class HooksController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def autobuild
    project = Project.where(:hook_name => params[:hook_name]).first
    if project
      trigger_and_respond(project)
    else
      render :text => "hook name %p not found" % [params[:hook_name]], :status => 404
    end
  end

  def github
    payload = JSON.parse(params[:payload])
    logger.info "Received a github hook: #{payload.to_yaml}"
    branch = payload["ref"].split("/").last
    url = payload["repository"]["url"]

    public_source = url.gsub(/^https:\/\//, "git://") + ".git"
    private_source = url.gsub(/^https:\/\//, "git@").
                         gsub(/github.com\//, "github.com:") + ".git"

    # If the repo in bigtuna is different than the one passed in --
    if (params[:host])
      public_source = url.gsub(/github.com/, params[:host])
      private_source=  url.gsub(/github.com/, params[:host])
      logger.info "Replaced host #{params[:host]}"
    end


    logger.info "Looking up #{public_source} , #{private_source} with branch #{branch}"
    project = Project.where(["(vcs_source = ? or vcs_source = ?) AND (vcs_branch = ?)",
                              public_source, private_source, branch]).first

    if (!project)
      project = Project.where(["(vcs_source = ? or vcs_source = ?) AND (build_any = ?)",
                              public_source, private_source, true]).first
      project.vcs_branch = branch
      project.save!
    end

    logger.info "Hitting [#{project}]"

    if BigTuna.github_secure.nil?
      render :text => "github secure token is not set up", :status => 403
    elsif project and params[:secure] == BigTuna.github_secure
      trigger_and_respond(project)
    else
      render :text => "invalid secure token", :status => 404
    end
  end

  def bitbucket
    payload = JSON.parse(params[:payload])
    branch = payload["commits"][0]["branch"]
    url = payload["repository"]["absolute_url"]
    source = "ssh://hg@bitbucket.org#{url}"

    project = Project.where(:vcs_source => source, :vcs_branch => branch).first

    if BigTuna.bitbucket_secure.nil?
      render :text => "bitbucket secure token is not set up", :status => 403
    elsif project and params[:secure] == BigTuna.bitbucket_secure
      trigger_and_respond(project)
    else
      render :text => "invalid secure token", :status => 404
    end
  end

  def configure
    @project = Project.find(params[:project_id])
    @hook = Hook.where(:project_id => @project.id, :hook_name => params[:name]).first
    return render if request.get?
    @hook.configuration = params["configuration"]
    @hook.hooks_enabled = (params["hooks_enabled"] || {}).keys
    @hook.save!
    redirect_to(project_config_hook_path(@project, @hook.backend.class::NAME))
  end

  private
  def trigger_and_respond(project)
    project.build!
    render :text => "build for %p triggered" % [project.name], :status => 200
  end
end
