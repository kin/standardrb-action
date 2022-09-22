# frozen_string_literal: true

class GithubCheckRunService
  CHECK_NAME = "StandardRB"

  def initialize(report, github_data, report_adapter)
    @report = report
    @github_data = github_data
    @report_adapter = report_adapter
    @client = GithubClient.new(@github_data[:token], user_agent: "standardrb-action")
  end

  def run
    puts "running github check"
    puts "github data:"
    pp @github_data
    puts ""

    puts "endpoint_url: #{endpoint_url}"
    puts ""
    resp = @client.post(
      endpoint_url,
      create_check_payload
    )
    puts "resp: #{resp}"

    id = resp["id"]
    puts "id: #{id}"

    @summary = @report_adapter.summary(@report)

    puts
    puts "summary:"
    puts @summary

    @annotations = @report_adapter.annotations(@report)

    puts
    puts "annotations:"
    puts @annotations

    @conclusion = @report_adapter.conclusion(@report)

    puts
    puts "conclusion:"
    puts @conclusion
    puts

    resp = @client.patch(
      "#{endpoint_url}/#{id}",
      update_check_payload
    )
    puts "patch resp:"
    puts resp
  end

  private

  def endpoint_url
    "/repos/#{@github_data[:owner]}/#{@github_data[:repo]}/check-runs"
  end

  def base_payload(status)
    {
      name: CHECK_NAME,
      head_sha: @github_data[:sha],
      status: status,
      started_at: Time.now.iso8601
    }
  end

  def create_check_payload
    base_payload("in_progress")
  end

  def update_check_payload
    base_payload("completed").merge!(
      conclusion: @conclusion,
      output: {
        title: CHECK_NAME,
        summary: @summary,
        annotations: @annotations
      }
    )
  end
end
