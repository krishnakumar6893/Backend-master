require 'fontli_util'
require 'deeptype_util'
require 's3_configration'

class DeepType
  include Mongoid::Document
  include MongoExtensions
  include Mongoid::Timestamps
  include FontliUtil
  include DeeptypeUtil
  include S3Configration

  field :content_image_path, type: String
  field :style_image_path, type: String
  field :result_image_path, type: String
  field :priority, type: String
  field :result_image_name, type: String
  field :status, type: String
  field :content_text, type: String

  belongs_to :user, index: true

  STYLES_FOLDER = "style_images/".freeze
  TEMP_FOLDER = "/tmp/".freeze
  FILE_EXTNSION = ".png".freeze
  CONTENT_FOLDER =  "content_images/".freeze

  RESULT_FOLDER = "result_images/".freeze

  NUMBER_OF_RETRIES_FOR_DEEP_TYPE_REQUEST = 3.freeze
  TIME_LAPSE_BETWEEN_RETRY = 120.freeze # 2 minutes
  ALLOWED_TYPES = ['image/jpg', 'image/jpeg', 'image/png'].freeze
  AWS_CONFIG = Fontli.load_erb_config('deep_type.yml')[Rails.env].symbolize_keys
  AWS_BUCKET = AWS_CONFIG.delete(:bucket)
  DEEP_TYPE_PATH = "http://s3.amazonaws.com/#{AWS_BUCKET}/".freeze

  class << self
    def get_style(key=nil)
      return "#{STYLES_FOLDER}Painting1.jpg" unless key

      styles_with_relative_path[key.to_s]
    end

    def create_submission(params)
      validate_image_type(params[:content_image].content_type)
      # if validate_submission_params(user_id, style_image_path, priority, encoaded_image_data) == false
      #   return {
      #           body: "",
      #           status: "Failure",
      #           error: 'in-valid Params'
      #           }
      # end

      random_name = FontliUtil.secure_random
      temp_image_path = TEMP_FOLDER + random_name + file_extension(params[:content_image].original_filename)
      FontliUtil.write_file(temp_image_path, params[:content_image].tempfile)

      s3_image_path = CONTENT_FOLDER + random_name + file_extension(params[:content_image].original_filename)
      content_image_path = upload_to_s3(temp_image_path, s3_image_path)

      FontliUtil.remove_file(temp_image_path)
      style_image_path = get_style(params[:style_image_id])

      # Request to deep-type standalone application
      # Request params for deep-type request.
      # return response as json as Success/Failure
      final_response = JSON.parse(DeeptypeUtil.communicate_deeptype_with({ style_image_path: style_image_path, content_image_path: content_image_path,
                                               result_image_path: RESULT_FOLDER, result_image_name: random_name, content_text: params[:content_text]}))

      # create a new table only if the status is succes from the deep-type

      if final_response["status"] == "Success"
        deep_type = DeepType.create!(user_id: params[:user_id], content_image_path: content_image_path,
                                     style_image_path: style_image_path, result_image_path: RESULT_FOLDER,
                                     priority: params[:priority], result_image_name: random_name,
                                     content_text: params[:content_text])
        final_response["content_image_path"] = content_image_path
        final_response["style_image_path"] = style_image_path
        final_response["content_text"] = params[:content_text]
        deep_type.decrement_user_points if deep_type.user
      end
      final_response["points"] = User.find(params[:user_id]).try(:points)

      return final_response
    end

    def validate_submission_params(*params)
      success = true
      for index in 0... params.length
        if params[index] == nil || params[index] ==""
          success = false
          break
        end
      end
      return success
    end

    # return integer specified as number of retries allowedd
    def retries_for_deep_type
      NUMBER_OF_RETRIES_FOR_DEEP_TYPE_REQUEST
    end

    # return integer specified as lapse in seconds between retries
    def time_lapse_between_retry
      TIME_LAPSE_BETWEEN_RETRY
    end

    # Generic Method for finding obj by attribute name and value
    def find_deeptype_by attr_name, value
      return nil unless column_names.include? attr_name.to_s

      where(attr_name => value.to_s)
    end

    # return all syyle values
    def get_style_values
      return styles_with_relative_path
    end

    def get_history user_id
      deep_types = DeepType.where(user_id: user_id).desc(:created_at)

      [].tap do |results|
        deep_types.each do |deep_type|
          result = { content_image_path: deep_type.content_image_path,
                     style_image_path: deep_type.style_image_path,
                     result_image_path: deep_type.result_image_path,
                     id: deep_type.id,
                     final_status: deep_type.status.presence || "inProgress",
                     created_at: deep_type.created_dt,
                     content_text: deep_type.content_text
                   }
          results << result
        end
      end
    end

    def get_result_images_for params
      find_deeptype_by(:result_image_name, params["result_image_name"]).map(&:result_image_path)
    end
  end

  def decrement_user_points
    point = Point.deep_type_points
    user.update_attributes(points: user.reload.points - point)
  end

  private

  class << self
    def styles_with_relative_path
      Rails.cache.fetch('deep_type_styles', expires_in: 1.day) do
        styles = S3Configration.get_bucket('style_images/').files.map(&:key)
        styles.delete("style_images/")
        {}.tap do |styles_hash|
          styles.each do |style|
            styles_hash[style.gsub("style_images/", '')] = DEEP_TYPE_PATH + style
          end
        end
      end
    end

    # This method will upload files to s3 bucket
    # See lib/s3_configration.rb for more details
    def upload_to_s3(file_to_upload, path)
      S3Configration.upload(file_to_upload, path)
    end

    def validate_image_type(type)
      unless ALLOWED_TYPES.include?(type)
        return { body: "", status: "Failure", error: 'Invalid image format' }
      end
    end

    def file_extension(filename)
      File.extname(filename)
    end
  end
end
