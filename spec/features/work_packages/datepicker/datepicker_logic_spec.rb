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
require 'support/edit_fields/edit_field'

describe 'Datepicker modal logic test cases (WP #43539)',
         with_settings: { date_format: '%Y-%m-%d' },
         js: true do
  shared_let(:user) { create :admin }

  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_milestone) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [type_bug, type_milestone]) }

  shared_let(:bug_wp) { create :work_package, project:, type: type_bug }
  shared_let(:milestone_wp) { create :work_package, project:, type: type_milestone }

  # assume sat+sun are non working days
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:date_attribute) { :combinedDate }
  let(:date_field) { work_packages_page.edit_field(date_attribute) }
  let(:datepicker) { date_field.datepicker }

  let(:work_package) { bug_wp }

  def apply_and_expect_saved(attributes)
    date_field.save!

    work_packages_page.expect_and_dismiss_toaster message: I18n.t('js.notice_successful_update')

    work_package.reload

    attributes.each do |attr, value|
      expect(work_package.send(attr)).to eq value
    end
  end

  before do
    work_package.update_columns(current_attributes)
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded

    date_field.activate!
    date_field.expect_active!
    # Wait for the datepicker to be initialized
    datepicker.expect_visible
  end

  context 'when only start_date set, updating duration (test case 1)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: nil,
        duration: nil
      }
    end

    it 'sets finish date' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      datepicker.set_duration 10

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-19')
    end
  end

  describe 'when no values set, updating duration (test case 2)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: nil
      }
    end

    it 'sets only the duration' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      datepicker.set_duration 10

      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: nil,
                             due_date: nil
    end
  end

  describe 'when only due date set, updating duration (test case 3)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: Date.parse('2021-02-19'),
        duration: nil
      }
    end

    it 'sets the start date' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration ''

      datepicker.set_duration 10

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-19')
    end
  end

  describe 'when all values set, increasing duration (test case 4)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-19'),
        duration: 10
      }
    end

    it 'updates the finish date to a later date' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      datepicker.set_duration 11

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-22'
      datepicker.expect_duration 11

      apply_and_expect_saved duration: 11,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-22')
    end
  end

  describe 'when all values set, reducing duration (test case 5)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-22'),
        duration: 11
      }
    end

    it 'updates the finish date to an earlier date' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-22'
      datepicker.expect_duration 11

      datepicker.set_duration 10

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-19')
    end
  end

  describe 'when all values set, removing duration (test case 6)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-12'),
        duration: 3
      }
    end

    it 'also unsets the due date' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 3

      # The spec clears faster than the due date is filled, wait a bit
      sleep 1
      datepicker.clear_duration

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date ''
      datepicker.expect_duration nil
    end
  end

  describe 'when all values set, removing duration through icon (test case 6a)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-12'),
        duration: 3
      }
    end

    it 'also unsets the due date' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 3

      # The spec clears faster than the due date is filled, wait a bit
      sleep 1
      datepicker.clear_duration_with_icon

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date ''
      datepicker.expect_duration nil
    end
  end

  describe 'when all values set, removing duration and setting it again' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-12'),
        duration: 3
      }
    end

    it 'allows re-deriving duration' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 3

      # The spec clears faster than the due date is filled, wait a bit
      sleep 1
      datepicker.clear_duration_with_icon

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date ''
      datepicker.expect_duration nil

      # Now select a date
      datepicker.select_day 5

      datepicker.expect_start_date '2021-02-05'
      datepicker.expect_due_date '2021-02-09'
      datepicker.expect_duration 3

      # Clear again
      sleep 1
      datepicker.clear_duration_with_icon

      datepicker.expect_start_date '2021-02-05'
      datepicker.expect_due_date ''
      datepicker.expect_duration nil

      datepicker.select_day 8
      datepicker.expect_start_date '2021-02-05'
      datepicker.expect_due_date '2021-02-08'
      datepicker.expect_duration 2
    end
  end

  describe 'when all values set, changing start date in calendar (test case 7)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-11'),
        duration: 4
      }
    end

    it 'adjusts the duration' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 4

      # With start date focused, change date in datepicker
      datepicker.focus_start_date
      datepicker.set_date '2021-02-09'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3
    end
  end

  # Same as scenario 7, with error state in the middle
  describe 'when all values set, setting the start date to invalid value, then to a valid value' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-11'),
        duration: 4
      }
    end

    it 'adjusts the duration' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 4

      # simulate someone deleting some chars to type a new date
      datepicker.set_start_date '2021-02-'
      sleep 2
      datepicker.set_start_date '2021-02-09'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3
    end
  end

  describe 'when all values set, changing due date (test case 8)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-12'),
        duration: 4
      }
    end

    it 'adjusts the duration' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 4

      datepicker.set_due_date '2021-02-11'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3
    end
  end

  describe 'when only duration set, setting finish date (test case 9)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: 4
      }
    end

    it 'derives the start date' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration 4

      datepicker.set_due_date '2021-02-12'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 4
    end
  end

  describe 'when only due date set, setting start date (test case 10)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: Date.parse('2021-02-11'),
        duration: nil
      }
    end

    it 'derives the duration' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration ''

      datepicker.set_start_date '2021-02-09'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3
    end
  end

  describe 'when all values set, changing the start date to the future in the picker (Scenario 13)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-11'),
        duration: 3
      }
    end

    it 'unsets the other two values' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3

      datepicker.set_date '2021-03-03'

      datepicker.expect_start_date '2021-03-03'
      datepicker.expect_due_date ''
      datepicker.expect_duration ''
    end
  end

  describe 'when all values set, changing the start date to the past in the picker (Scenario 14)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-11'),
        duration: 3
      }
    end

    it 'conserves the duration and updates the finish date' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3

      datepicker.set_date '2021-02-03'

      datepicker.expect_start_date '2021-02-03'
      datepicker.expect_due_date '2021-02-05'
      datepicker.expect_duration 3
    end
  end

  describe 'when all values set, changing include NWD to true (Scenario 15)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-11'),
        due_date: Date.parse('2021-02-16'),
        duration: 4
      }
    end

    it 'conserves the duration and updates the finish date' do
      datepicker.expect_start_date '2021-02-11'
      datepicker.expect_due_date '2021-02-16'
      datepicker.expect_duration 4

      datepicker.ignore_non_working_days true

      datepicker.expect_start_date '2021-02-11'
      datepicker.expect_due_date '2021-02-14'
      datepicker.expect_duration 4
    end
  end

  describe 'when all values set and include NWD true, changing include NWD to false (Scenario 16)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-11'),
        due_date: Date.parse('2021-02-14'),
        duration: 4,
        ignore_non_working_days: true
      }
    end

    it 'conserves the duration and updates the finish date' do
      datepicker.expect_start_date '2021-02-11'
      datepicker.expect_due_date '2021-02-14'
      datepicker.expect_duration 4
      datepicker.expect_ignore_non_working_days true

      datepicker.ignore_non_working_days false

      datepicker.expect_ignore_non_working_days false
      datepicker.expect_start_date '2021-02-11'
      datepicker.expect_due_date '2021-02-16'
      datepicker.expect_duration 4
    end
  end

  describe 'when all values set and include NWD true, changing include NWD to false (Scenario 17)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-13'),
        due_date: Date.parse('2021-02-14'),
        duration: 2,
        ignore_non_working_days: true
      }
    end

    it 'shifts the start date to soonest working day, and updates finish date to conserve duration' do
      datepicker.expect_start_date '2021-02-13'
      datepicker.expect_due_date '2021-02-14'
      datepicker.expect_duration 2
      datepicker.expect_ignore_non_working_days true

      datepicker.ignore_non_working_days false

      datepicker.expect_ignore_non_working_days false
      datepicker.expect_start_date '2021-02-15'
      datepicker.expect_due_date '2021-02-16'
      datepicker.expect_duration 2
    end
  end

  describe 'when all values set and include NWD true, changing include NWD to false (Scenario 18)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-13'),
        due_date: Date.parse('2021-02-23'),
        duration: 11,
        ignore_non_working_days: true
      }
    end

    it 'shifts the start date to soonest working day, and updates finish date to conserve duration' do
      datepicker.expect_start_date '2021-02-13'
      datepicker.expect_due_date '2021-02-23'
      datepicker.expect_duration 11
      datepicker.expect_ignore_non_working_days true

      datepicker.ignore_non_working_days false

      datepicker.expect_ignore_non_working_days false
      datepicker.expect_start_date '2021-02-15'
      datepicker.expect_due_date '2021-03-01'
      datepicker.expect_duration 11

      apply_and_expect_saved duration: 11,
                             start_date: Date.parse('2021-02-15'),
                             due_date: Date.parse('2021-03-01'),
                             ignore_non_working_days: false
    end
  end

  describe 'when only start date set and include NWD true, changing include NWD to false (Scenario 19)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-13'),
        due_date: nil,
        duration: nil,
        ignore_non_working_days: true
      }
    end

    it 'shifts the start date to soonest working day' do
      datepicker.expect_start_date '2021-02-13'
      datepicker.expect_due_date ''
      datepicker.expect_duration ''
      datepicker.expect_ignore_non_working_days true

      datepicker.ignore_non_working_days false

      datepicker.expect_ignore_non_working_days false
      datepicker.expect_start_date '2021-02-15'
      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      apply_and_expect_saved duration: nil,
                             start_date: Date.parse('2021-02-15'),
                             due_date: nil,
                             ignore_non_working_days: false
    end
  end

  describe 'when only finish date set and include NWD true, changing include NWD to false (Scenario 20)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: Date.parse('2021-02-21'),
        duration: nil,
        ignore_non_working_days: true
      }
    end

    it 'shifts the finish date to soonest working day' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date '2021-02-21'
      datepicker.expect_duration ''
      datepicker.expect_ignore_non_working_days true

      datepicker.ignore_non_working_days false

      datepicker.expect_ignore_non_working_days false
      datepicker.expect_start_date ''
      datepicker.expect_due_date '2021-02-22'
      datepicker.expect_duration ''

      apply_and_expect_saved duration: nil,
                             start_date: nil,
                             due_date: Date.parse('2021-02-22'),
                             ignore_non_working_days: false
    end
  end

  describe 'When all values set, clear the start date (Scenario 21a)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-20'),
        due_date: Date.parse('2021-02-21'),
        duration: 1,
        ignore_non_working_days: true
      }
    end

    it 'also removes duration, but keeps finish date' do
      datepicker.expect_start_date '2021-02-20'
      datepicker.expect_due_date '2021-02-21'
      datepicker.expect_duration 1
      datepicker.expect_ignore_non_working_days true

      datepicker.set_start_date ''
      datepicker.expect_duration ''
      datepicker.expect_due_date '2021-02-21'

      apply_and_expect_saved duration: nil,
                             start_date: nil,
                             due_date: Date.parse('2021-02-21'),
                             ignore_non_working_days: true
    end
  end

  describe 'When all values set, clear the due date (Scenario 21a)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-20'),
        due_date: Date.parse('2021-02-21'),
        duration: 1,
        ignore_non_working_days: true
      }
    end

    it 'also removes duration, but keeps start date' do
      datepicker.expect_start_date '2021-02-20'
      datepicker.expect_due_date '2021-02-21'
      datepicker.expect_duration 1
      datepicker.expect_ignore_non_working_days true

      datepicker.set_due_date ''
      datepicker.expect_duration ''
      datepicker.expect_start_date '2021-02-20'

      apply_and_expect_saved duration: nil,
                             start_date: Date.parse('2021-02-20'),
                             due_date: nil,
                             ignore_non_working_days: true
    end
  end

  describe 'when all values set and duration highlighted, selecting date in datepicker' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-11'),
        duration: 4
      }
    end

    it 'sets start to the selected value, keeps finish date' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 4

      # Focus duration
      datepicker.duration_field.click
      datepicker.expect_duration_highlighted

      # Select date in datepicker
      datepicker.select_day 5

      datepicker.expect_start_date '2021-02-05'
      datepicker.expect_due_date '2021-02-10'
      datepicker.expect_duration 4

      # Focus is on finish date
      datepicker.expect_due_highlighted
      datepicker.select_day 15

      datepicker.expect_start_date '2021-02-05'
      datepicker.expect_due_date '2021-02-15'
      datepicker.expect_duration 7

      apply_and_expect_saved duration: 7,
                             start_date: Date.parse('2021-02-05'),
                             due_date: Date.parse('2021-02-15')
    end
  end

  describe 'when all values set and duration highlighted, selecting dates in datepicker' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: nil
      }
    end

    it 'sets start to the selected value, moves to finish date' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      # Focus duration
      datepicker.duration_field.click
      datepicker.expect_duration_highlighted

      # Select date in datepicker
      datepicker.set_date Date.parse('2021-02-05')

      datepicker.expect_start_date '2021-02-05'
      datepicker.expect_due_highlighted

      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      datepicker.select_day 9

      datepicker.expect_start_date '2021-02-05'
      datepicker.expect_due_date '2021-02-09'
      datepicker.expect_duration 3

      apply_and_expect_saved duration: 3,
                             start_date: Date.parse('2021-02-05'),
                             due_date: Date.parse('2021-02-09')
    end
  end

  context 'when setting ignore NWD to true for a milestone' do
    let(:date_attribute) { :date }
    let(:work_package) { milestone_wp }
    let(:current_attributes) do
      {
        start_date: '2022-06-20',
        due_date: '2022-06-20',
        ignore_non_working_days: false
      }
    end

    it 'allows to persist that value (Regression #43932)' do
      datepicker.expect_milestone_date '2022-06-20'
      datepicker.expect_ignore_non_working_days false

      datepicker.ignore_non_working_days true

      datepicker.expect_ignore_non_working_days true
      datepicker.expect_milestone_date '2022-06-20'

      # Set date to sunday
      datepicker.set_milestone_date '2022-06-19'
      apply_and_expect_saved start_date: Date.parse('2022-06-19'),
                             due_date: Date.parse('2022-06-19'),
                             ignore_non_working_days: true
    end
  end

  context 'when setting start and due date through today links' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: nil,
        ignore_non_working_days: true
      }
    end

    it 'allows to persist that value (Regression #44140)' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      today = Time.zone.today
      today_str = today.iso8601

      # Setting start will set active to due
      datepicker.set_today 'start'
      datepicker.expect_start_date today_str
      datepicker.expect_due_highlighted

      datepicker.set_today 'due'
      datepicker.expect_due_date today_str
      datepicker.expect_start_highlighted

      datepicker.expect_duration 1

      apply_and_expect_saved start_date: today,
                             due_date: today,
                             duration: 1
    end
  end
end
