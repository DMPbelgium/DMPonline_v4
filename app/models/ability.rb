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

      can [:index,:new,:create,:destroy,:parent,:children,:templates], Organisation
      can [:edit,:update,:delete_recent_locks,:unlock_all_sections,:lock_section,:unlock_section], Plan do |plan|
        plan.editable_by(user.id)
      end

      can [:status,:section_answers,:locked,:answer,:warning,:export], Plan do |plan|
        plan.readable_by(user.id)
      end

      can :create,Answer do |answer|
        answer.plan.editable_by(user.id)
      end

      can :index,Comment
      can [:create,:show,:edit,:update,:archive],Comment
      can :manage_settings, User do |viewed_user|
        viewed_user.present? && user.id == viewed_user.id
      end

      can [:create,:update,:destroy], ProjectGroup do |pg|
        pg.project.administerable_by(user.id)
      end

      can [:index,:new,:export,:create],Project
      can :show,Project do |p|
        p.readable_by(user.id)
      end
      can [:edit,:update],Project do |p|
        p.editable_by(user.id)
      end
      can [:share,:destroy], Project do |p|
        p.administerable_by(user.id)
      end


      if user.has_role? :admin

        #TODO: all org_admin actions forbidden (actions that start with 'admin_'), for they load other resources based on the current_user?
        can :manage, :all

      elsif user.is_org_admin?

        can :manage, Dmptemplate
        can :manage, GuidanceGroup
        can [:admin_show,:admin_edit,:admin_update],Organisation

      end

      can :emails, User

    end
  end
end
