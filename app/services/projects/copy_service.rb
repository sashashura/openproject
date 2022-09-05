#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  class CopyService < ::BaseServices::Copy
    include Projects::Concerns::NewProjectService

    def self.copy_dependencies
      [
        ::Projects::Copy::MembersDependentService,
        ::Projects::Copy::VersionsDependentService,
        ::Projects::Copy::CategoriesDependentService,
        ::Projects::Copy::WorkPackagesDependentService,
        ::Projects::Copy::WikiDependentService,
        ::Projects::Copy::WikiPageAttachmentsDependentService,
        ::Projects::Copy::ForumsDependentService,
        ::Projects::Copy::QueriesDependentService,
        ::Projects::Copy::BoardsDependentService,
        ::Projects::Copy::OverviewDependentService,
        ::Projects::Copy::StoragesDependentService,
        ::Projects::Copy::FileLinksDependentService
      ]
    end

    protected

    ##
    # Whether to skip the given key.
    # Useful when copying nested dependencies
    def skip_dependency?(params, dependency_cls)
      !Copy::Dependency.should_copy?(params, dependency_cls.identifier.to_sym)
    end

    def set_attributes_params(params)
      attributes = source.attributes.dup.except(*skipped_attributes)
      # Clear enabled modules
      attributes[:enabled_module_names] = source.enabled_module_names - %w[repository]
      attributes[:types] = source.types
      attributes[:work_package_custom_fields] = source.work_package_custom_fields

      # Copy status object
      attributes[:status] = source.status&.dup

      # Take over the CF values for attributes
      attributes[:custom_field_values] = source.custom_value_attributes

      attributes.merge(cleaned_target_project_params)
    end

    def before_perform(params, service_call)
      super.tap do |super_call|
        # Retain values after the set attributes service
        retain_attributes(source, super_call.result, target_project_params)

        # Retain the project in the state for other dependent
        # copy services to use
        state.project = super_call.result
      end
    end

    def contract_options
      { copy_source: source, validate_model: true }
    end

    def retain_attributes(source, target, target_project_params)
      # Ensure we keep the public value of the source project
      # which might get overridden by the SetAttributesService
      # unless the user provided a different value
      target.public = source.public unless target_project_params.key?(:public)
    end

    def skipped_attributes
      %w[id created_at updated_at name identifier active templated lft rgt]
    end

    # Additional input target params
    def target_project_params
      params[:target_project_params].with_indifferent_access
    end

    def cleaned_target_project_params
      if (parent_id = target_project_params[:parent_id]) && (parent = Project.find_by(id: parent_id)) &&
        !user.allowed_to?(:add_subprojects, parent)
        target_project_params.except(:parent_id)
      else
        target_project_params
      end
    end
  end
end
