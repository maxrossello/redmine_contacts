# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2017 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class ContactTest < ActiveSupport::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries
  fixtures :email_addresses if ActiveRecord::VERSION::MAJOR >= 4

  RedmineContacts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :contacts_issues,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries])

  def setup
    RedmineContacts::TestCase.prepare
  end

  # Replace this with your real tests.
  def test_find_by_emails_first_email
    emails = ["marat@mail.ru", "domoway@mail.ru"]
    assert_equal 2, Contact.find_by_emails(emails).count
  end

  def test_find_by_emails_second_email
    emails = ["marat@mail.com"]
    assert_equal 1, Contact.find_by_emails(emails).count
  end

  def test_scope_live_search
    assert_equal 4, Contact.live_search('john').first.try(:id)
  end

  def test_visible_public_contacts
    project = Project.find(1)
    contact = Contact.find(1)
    user = User.find(1) # John Smith

    contact.visibility = Contact::VISIBILITY_PUBLIC
    contact.save!

    assert contact.visible?(user)
  end

  def test_visible_scope_for_non_member_without_view_contacts_permissions
    # Non member user should not see issues without permission
    Role.non_member.remove_permission!(:view_contacts)
    user = User.find(9)
    assert user.projects.empty?
    contacts = Contact.visible(user).all
    assert contacts.empty?
    assert_visibility_match user, contacts
  end

  def test_visible_scope_for_member
    user = User.find(2)
    # User should see issues of projects for which he has view_issues permissions only
    role = Role.create!(:name => 'CRM', :permissions => [:view_contacts])
    Role.non_member.remove_permission!(:view_contacts)
    project = Project.find(2)
    Contact.delete_all
    Member.delete_all(:user_id => user)
    member = Member.create!(:principal => user, :project_id => project.id, :role_ids => [role.id])
    contact = Contact.create!(:project => project, :first_name => "UnitTest", :visibility => Contact::VISIBILITY_PUBLIC)

    contacts = Contact.visible(user).all

    assert contacts.any?
    assert_nil contacts.detect {|c| c.project.id != project.id }
    # assert_nil contacts.detect {|c| c.is_private?}
    assert_visibility_match user, contacts

    contact.visibility = Contact::VISIBILITY_PRIVATE
    contact.save!
    contacts = Contact.visible(user).all
    assert contacts.blank?, "Private contacts are visible"


    assert user.allowed_to?(:view_contacts, project)
    contact.visibility = Contact::VISIBILITY_PROJECT
    contact.save!
    contacts = Contact.visible(user).all
    assert contacts.any?, "Project contacts doesn't visible with permissions"

    role.remove_permission!(:view_contacts)
    user.reload
    contact.visibility = Contact::VISIBILITY_PROJECT
    contact.save!
    contacts = project.contacts.visible(user).all
    assert contacts.blank?, "Contacts visible for user without view_contacts permissions"

    role.add_permission!(:view_private_contacts)
    user.reload
    contact.visibility = Contact::VISIBILITY_PRIVATE
    contact.save!
    contacts = Contact.visible(user).all
    assert contacts.any?, "Contacts note visible for user with view_private_contacts permissions"
  end

  def test_create_should_send_email_notification
    ActionMailer::Base.deliveries.clear
    contact = Contact.new(:first_name => "New contact", :project => Project.find(1))

    with_settings :notified_events => %w(crm_contact_added) do
      assert contact.save
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  def assert_visibility_match(user, contacts)
    assert_equal contacts.collect(&:id).sort, Contact.all.select {|contact| contact.visible?(user)}.collect(&:id).sort
  end

  def test_emails_format_for_contact
    project = Project.find(1)
    assert_equal true, Contact.new(:project => project, :first_name => 'Test', :email => 'test+2-1@test.com').valid?
    assert_equal true, Contact.new(:project => project, :first_name => 'Test', :email => ' test+2-1@test.com ').valid?
    assert_equal true, Contact.new(:project => project, :first_name => 'Test', :email => 'test+2-1@test.com,').valid?
    assert_equal true, Contact.new(:project => project, :first_name => 'Test', :email => 'test+2-1@test.com,foo@bar.com,tt@tt.ru').valid?
    assert_equal true, Contact.new(:project => project, :first_name => 'Test', :email => 'test+2-1@test.com, foo@bar.com').valid?
  end

  def test_email_transformation_on_create
    assert_equal 'test@test.com', Contact.create!(:project => Project.find(1), :first_name => 'Test', :email => ' test@test.com    ').email
    assert_equal 'test@test.com,foo@bar.com', Contact.create!(:project => Project.find(1), :first_name => 'Test', :email => ' test@test.com  , foo@bar.com  ').email
  end
end
