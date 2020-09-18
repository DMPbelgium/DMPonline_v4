class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    #/answers
    can :create,SplashLog

    #USE of these controllers? ActiveAdmin has its own crud actions!
    #better to switch them off, and put them back online when needed

    #can :manage,Theme
    #can :manage,UserOrgRole
    #can :manage,UserRoleType
    #can :manage,User
    #can :manage,UserStatus
    #can :manage,UserType

    if user.persisted?

      can [:edit,:update,:delete_recent_locks,:unlock_all_sections,:lock_section,:unlock_section], Plan do |plan|
        plan.editable_by(user.id)
      end

      can [:status,:section_answers,:locked,:answer,:warning,:export], Plan do |plan|
        plan.readable_by(user.id)
      end

      can :create,Answer do |answer|
        answer.plan.editable_by(user.id)
      end

      can :create, Comment do |comment|
        comment.creatable_by( user.id )
      end
      can :show, Comment do |comment|
        comment.readable_by( user.id )
      end
      can [:edit,:update], Comment do |comment|
        comment.editable_by( user.id )
      end
      can :archive, Comment do |comment|
        comment.archivable_by( user.id )
      end

      can :manage_settings, User do |viewed_user|
        viewed_user.present? && user.id == viewed_user.id
      end

      can [:create], ProjectGroup do |pg|
        pg.project.administerable_by(user.id)
      end

      can [:update,:destroy], ProjectGroup do |pg|

        v = false

        if pg.project.administerable_by(user.id)

          v = true

          #cannot remove creator
          if pg.project_creator
            v = false

          #Data Protection Officers are added automatically and so should not be removed.
          elsif pg.project_gdpr

            project = pg.project
            dmptemplate = project.dmptemplate

            #gdpr template
            if dmptemplate.gdpr

              organisation = project.organisation

              #gdpr, but no organisation: no dpo's should be added
              if organisation.nil?

                v = true

              #organisational dpo?
              else

                v = !(organisation.gdprs.any? {|u| u.id == pg.user_id })

              end

            #dpo in non gdpr template? can be removed
            else

              v = true

            end

          end

        else

          v = false

        end

        v

      end

      can [:index,:show,:export],Project do |p|
        p.readable_by(user.id)
      end
      unless user.is_guest?
        can [:new,:create], Project
      end
      can [:edit,:update], Project do |p|
        p.editable_by(user.id)
      end
      can [:destroy,:share], Project do |p|
        p.administerable_by(user.id)
      end

      if user.has_role? :admin

        can :manage, :all
        #'can' does not override 'can', but is logically or'ed
        cannot [:edit,:update], Comment do |comment|
          !comment.editable_by( user.id )
        end
        cannot [:update,:destroy], ProjectGroup do |pg|
          pg.project_creator
        end

      elsif user.is_org_admin?

        # :admin_index
        #   GET /org/admin/templates/:organisation_id/admin_template
        #     parameter :organisation_id is ignored, and not necessary
        # :admin_new
        #   GET /org/admin/templates/:organisation_id/admin_new
        # :admin_create
        #   POST /org/admin/templates/:organisation_id/admin_create
        can [:admin_index,:admin_new,:admin_create], Dmptemplate

        # GET /org/admin/templates/:dmptemplate_id/admin_template
        #   show own or funder template
        can [:admin_template], Dmptemplate do |t|
          t.organisation_id == user.organisation_id ||
          t.org_type() == "Funder"
        end
        # GET /org/admin/templates/:dmptemplate_id/admin_addphase
        #   add phase to own template
        can [:admin_addphase], Dmptemplate do |t|
          t.organisation_id == user.organisation_id
        end

        # PUT /org/admin/templates/:dmptemplate_id/admin_update
        #    update attributes of own templates only
        can [:admin_update,:admin_destroy], Dmptemplate do |t|
          t.organisation_id == user.organisation_id
        end

        can [:admin_createphase], Phase do |phase|
          phase.present? &&
          phase.new_record? &&
          phase.dmptemplate.present? &&
          phase.dmptemplate.organisation_id == user.organisation_id
        end

        # :admin_phase
        #   GET /org/admin/templates/:phase_id/admin_phase
        can [:admin_phase], Phase do |phase|
          phase.dmptemplate.organisation_id == user.organisation_id ||
          phase.dmptemplate.org_type() == "Funder"
        end

        # :admin_updatephase
        #   PUT /org/admin/templates/:phase_id/admin_updatephase
        can [:admin_updatephase], Phase do |phase|
          phase.dmptemplate.organisation_id == user.organisation_id
        end

        # :admin_destroyphase
        #   DELETE /org/admin/templates/:phase_id/admin_updatephase
        can [:admin_destroyphase], Phase do |phase|
          phase.dmptemplate.organisation_id == user.organisation_id &&
          phase.latest_published_version == nil
        end

        # :admin_previewphase
        can [:admin_previewphase], Version do |version|
          version.phase.dmptemplate.organisation_id == user.organisation_id ||
          version.phase.dmptemplate.org_type() == "Funder"
        end

        # :admin_updateversion
        #   PUT /org/admin/templates/:version_id/admin_updateversion
        can [:admin_updateversion,:admin_cloneversion], Version do |version|
          version.present? && version.phase.present? && version.phase.dmptemplate.present? &&
          version.phase.dmptemplate.organisation_id == user.organisation_id
        end

        can [:admin_destroyversion], Version do |version|
          version.phase.dmptemplate.organisation_id == user.organisation_id &&
          !(version.published)
        end

        # :admin_createsection
        #   POST /org/admin/templates/271/admin_createsection
        can [:admin_createsection], Section do |section|
          section.present? && section.new_record? &&
          section.version.present? && section.version.phase.present? &&
          section.version.phase.dmptemplate.present? &&
          #only add section with same org as your own
          section.organisation_id == user.organisation_id &&
          #only add section to section to own templates, or customize funder templates
          (
            section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end

        can [:admin_updatesection], Section do |section|
          #only update section with same org as your own
          section.organisation_id == user.organisation_id &&
          #only update section for own templates, or customize funder templates
          (
            section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end

        can [:admin_destroysection], Section do |section|
          #only destroy your own sections of an unpublished version
          section.organisation_id == user.organisation_id &&
          !(section.version.published)
        end

        can [:admin_createquestion], Question do |question|
          question.present? && question.new_record? &&
          question.section.present? &&
          question.section.organisation_id == user.organisation_id &&
          !(question.section.version.published) &&
          (
            question.section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            question.section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end
        can [:admin_updatequestion], Question do |question|
          question.section.organisation_id == user.organisation_id &&
          !(question.section.version.published) &&
          (
            question.section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            question.section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end
        can [:admin_destroyquestion], Question do |question|
          question.section.organisation_id == user.organisation_id &&
          !(question.section.version.published) &&
          (
            question.section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            question.section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end

        can :admin_createsuggestedanswer, SuggestedAnswer do |sa|
          sa.present? && sa.new_record? &&
          sa.question.section.present? &&
          sa.organisation_id == user.organisation_id &&
          !(sa.question.section.version.published) &&
          (
            sa.question.section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            sa.question.section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end
        can :admin_updatesuggestedanswer, SuggestedAnswer do |sa|
          sa.organisation_id == user.organisation_id &&
          !(sa.question.section.version.published) &&
          (
            sa.question.section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            sa.question.section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end
        can :admin_destroysuggestedanswer, SuggestedAnswer do |sa|
          sa.organisation_id == user.organisation_id &&
          !(sa.question.section.version.published) &&
          (
            sa.question.section.version.phase.dmptemplate.organisation_id == user.organisation_id ||
            sa.question.section.version.phase.dmptemplate.org_type() == "Funder"
          )
        end

        #GuidanceGroup - start
        can [:admin_new,:admin_create], GuidanceGroup
        can [:admin_show,:admin_edit,:admin_update,:admin_destroy], GuidanceGroup do |gg|
          gg.organisation_id == user.organisation_id
        end
        #GuidanceGroup - end

        can [:admin_index,:admin_new], Guidance
        can [:admin_create,:admin_show,:admin_edit,:admin_update,:admin_destroy], Guidance do |g|
          g.guidance_groups.any? {|gg| gg.organisation_id == user.organisation_id }
        end

        can [:admin_show,:admin_edit,:admin_update],Organisation

      end

    end
  end
end
