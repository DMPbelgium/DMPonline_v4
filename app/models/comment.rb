class Comment < ActiveRecord::Base

  #associations between tables
  belongs_to :question, :inverse_of => :comments, :autosave => true
  belongs_to :user, :inverse_of => :comments, :autosave => true
  belongs_to :plan

  validates :question, :presence => true
  validates :user, :presence => true
  validates :text, :length => { :minimum => 1 }

  #fields
  attr_accessible :question_id, :text, :user_id, :archived, :plan_id, :archived_by

  def to_s
      "#{text}"
  end

  #I know, but the attribute archived_by was already taken for the user id
  def archiver
    return nil if archived_by.nil?
    archived_by.present? ?
      User.where( :id => archived_by ).first : nil
  end
  def archiver_name
    a = self.archiver
    a.nil? ? "(deleted user)" : a.name
  end

  def self.not_archived
    where( "archived_by is NULL" )
  end

  def self.archived
    where( "archived_by is NOT NULL" )
  end

  def creatable_by(other_user_id)
    return false if other_user_id.nil?
    return false if self.plan_id.nil?
    pl = Plan.where( :id => self.plan_id ).first
    return false if pl.nil?
    return false if pl.project.nil?
    pl.project.editable_by(other_user_id)
  end

  def readable_by(other_user_id)
    return false if other_user_id.nil?

    self.user_id.nil? ?
      false :
      self.user_id == other_user_id || Plan.find( self.plan_id ).project.readable_by(other_user_id)
  end

  def editable_by(other_user_id)
    return false if other_user_id.nil?

    self.user_id.nil? ?
      false :
      self.user_id == other_user_id
  end

  def archivable_by(other_user_id)
    return false if other_user_id.nil?
    return false if self.user_id.nil?
    return true if self.editable_by(other_user_id)
    return false if self.plan_id.nil?
    self.plan.project.administerable_by(other_user_id)
  end
end
