# == Schema Information
#
# Table name: openai_contents
#
#  id           :bigint           not null, primary key
#  about        :text
#  example_code :text
#  faqs         :text
#  tags         :text
#  use_cases    :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  project_id   :integer
#
# Indexes
#
#  index_openai_contents_on_project_id  (project_id)
#
class OpenaiContent < ApplicationRecord
    belongs_to :project
end
