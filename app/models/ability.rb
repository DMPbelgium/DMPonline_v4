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
            v = !(pg.project.dmptemplate.organisation.gdprs.any? {|u| u.id == pg.user_id })
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
      can [:edit,:update,:share,:destroy], Project do |p|
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

        can :manage, Dmptemplate
        can :manage, GuidanceGroup
        can [:admin_show,:admin_edit,:admin_update],Organisation

      end

    end
  end
end
