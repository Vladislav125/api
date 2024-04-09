class StorageApiController < ApplicationController

  # before_action :check_object, only: %i[destroy rename_obj]
  # before_action :set_redirect_param, only: %i[s3_object_url]

  # def index
  #   unless params[:prefix].blank? || object_exists?(params[:prefix])
  #     # ошибка, если префикс не указан или не существует
  #     render json: { error: "No such directory '#{params[:prefix]}'" }

  #     return
  #   end

  #   # JSON с данными о файлах
  #   render json: S3Selectel::AllFile.call(params[:prefix])
  # end

  def upload_file # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    file_key = file_params[:key]

    path_dir = "#{File.dirname(file_key)}/"
    unless object_exists?(path_dir)
      render json: { error: "No such directory '#{path_dir}'" }

      return
    end
    
    file_size = File.size(file_params[:body].to_path)
    project_id = file_params[:project_id]
    subproject_id = file_params[:subproject_id]
    category_id = file_params[:category_id]

    @file = User.find_by(email: user_params[:user_email]).files_blobs.find_by(filename: file_key)

    if @file.present?
      @file.update(
        project_id:,
        subproject_id:,
        category_id:,
        byte_size: file_size,
        description: file_params[:description],
        progress_status: file_params[:progress_status]
      )
    else
      unless uploadFile(file_params, user_params[:user_email])
        return
      end
    end
  end

  private

  def file_params
    params.require(:file).permit(
      :key,
      :body,
      :project_id,
      :subproject_id,
      :category_id,
      :description,
      :progress_status
    )
  end

  def user_params
    params.permit(:user_email)
  end

  def object_exists?(path)
    Dir.exist? path
  end

  def uploadFile(file_params, user_email)
    u = User.find_by(email: user_email)
    unless u
      return false
    end
    u.files.attach(io: file_params[:body], filename: file_params[:key])
    unless ActiveStorage::Blob.last.filename == file_params[:key]
      return false
    end
    ActiveStorage::Blob.last.update_column(:path, file_params[:path])
    true
  end
end
