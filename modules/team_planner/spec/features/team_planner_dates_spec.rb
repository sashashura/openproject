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

require 'spec_helper'
require_relative './shared_context'

describe 'Team planner working days', type: :feature, js: true do
  before do
    with_enterprise_token(:team_planner_view)
  end

  include_context 'with team planner full access'

  context 'with week days defined' do
    let!(:week_days) { week_with_saturday_and_sunday_as_weekend }

    it 'renders sat and sun as non working' do
      team_planner.visit!

      team_planner.expect_empty_state
      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add user.name
      end

      expect(page).to have_selector('.fc-day-sat.fc-non-working-day', minimum: 1, wait: 10)
      expect(page).to have_selector('.fc-day-sun.fc-non-working-day', minimum: 1)

      expect(page).to have_no_selector('.fc-day-mon.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-tue.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-wed.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-thu.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-fri.fc-non-working-day')

      find('.fc-next-button').click

      expect(page).to have_selector('.fc-day-sat.fc-non-working-day', minimum: 1, wait: 10)
      expect(page).to have_selector('.fc-day-sun.fc-non-working-day', minimum: 1)

      expect(page).to have_no_selector('.fc-day-mon.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-tue.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-wed.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-thu.fc-non-working-day')
      expect(page).to have_no_selector('.fc-day-fri.fc-non-working-day')
    end
  end

  context 'with all days marked as weekend' do
    let!(:week_days) { week_with_no_working_days }

    it 'renders all as non working' do
      team_planner.visit!

      team_planner.expect_empty_state
      retry_block do
        team_planner.click_add_user
        page.find('[data-qa-selector="tp-add-assignee"] input')
        team_planner.select_user_to_add user.name
      end

      expect(page).to have_selector('.fc-day-sat.fc-non-working-day', minimum: 1, wait: 10)
      expect(page).to have_selector('.fc-day-sun.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-mon.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-tue.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-wed.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-thu.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-fri.fc-non-working-day', minimum: 1)

      find('.fc-next-button').click

      expect(page).to have_selector('.fc-day-sat.fc-non-working-day', minimum: 1, wait: 10)
      expect(page).to have_selector('.fc-day-sun.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-mon.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-tue.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-wed.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-thu.fc-non-working-day', minimum: 1)
      expect(page).to have_selector('.fc-day-fri.fc-non-working-day', minimum: 1)
    end
  end
end
