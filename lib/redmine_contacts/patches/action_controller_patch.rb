# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2018 RedmineUP
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

module RedmineContacts
  module Patches
    module ActionControllerPatch
      def self.included(base)
        base.extend(ClassMethods) if Rails::VERSION::MAJOR < 4

        base.class_eval do
        end
      end

      module ClassMethods
        if Rails::VERSION::MAJOR < 4
          def before_action(*filters, &block)
            before_filter(*filters, &block)
          end

          def after_action(*filters, &block)
            after_filter(*filters, &block)
          end

          def skip_before_action(*filters)
            skip_before_filter(*filters)
          end
        end
      end
    end
  end
end

unless ActionController::Base.included_modules.include?(RedmineContacts::Patches::ActionControllerPatch)
  ActionController::Base.send(:include, RedmineContacts::Patches::ActionControllerPatch)
end
