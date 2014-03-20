task recalculate_points: :environment do
  PullRequest.delete_all
  Score.reset

  Octokit.auto_paginate = true

  client = User.first.github_client

  client.organization_repositories('alphasights').map(&:full_name).each do |repo|
    client.pull_requests(repo, state: 'closed').each do |pr|
      user = User.where(nickname: pr.user.login).first

      next unless user

      pr_data = pr.rels[:self].get.data

      puts "#{repo} #{pr.number} #{pr.user.login} #{pr_data.merged_at} #{'weekly' if pr_data.merged_at && pr_data.merged_at > Time.now.beginning_of_week}"

      pull_request = PullRequest.new(
        user: user,
        merged: true,
        number: pr.number,
        base_repo_full_name: repo,
        number_of_comments: pr_data.comments,
        number_of_commits: pr_data.commits,
        number_of_additions: pr_data.additions,
        number_of_deletions: pr_data.deletions,
        number_of_changed_files: pr_data.changed_files,
        merged_at: pr_data.merged_at
      )

      puts pull_request.errors.full_messages unless pull_request.save
    end
  end

  TaskCompletion.all.each { |tc| tc.send(:give_points_to_user) }
end

task update_points_system: :environment do
  Score.reset
  PullRequest.all.each { |pr| pr.send(:give_points_to_user) }
  PullRequestReview.all.each { |prr| prr.send(:give_points_to_user) }
  TaskCompletion.all.each { |tc| tc.send(:give_points_to_user) }
end
