
require 'gitlab/email/handler/base_handler'

module Gitlab
  module Email
    module Handler
      class CreateIssueHandler < BaseHandler
        attr_reader :project_path, :authentication_token

        def initialize(mail, mail_key)
          super(mail, mail_key)
          @project_path, @authentication_token =
            mail_key && mail_key.split('+', 2)
        end

        def can_handle?
          !authentication_token.nil?
        end

        def execute
          raise ProjectNotFound unless project

          validate_permission!(:create_issue)

          verify_record!(
            record: create_issue,
            invalid_exception: InvalidIssueError,
            record_name: 'issue')
        end

        def author
          @author ||= User.find_by(authentication_token: authentication_token)
        end

        def project
          @project ||= Project.find_with_namespace(project_path)
        end

        private

        def create_issue
          Issues::CreateService.new(
            project,
            author,
            title:       mail.subject,
            description: message
          ).execute
        end
      end
    end
  end
end
