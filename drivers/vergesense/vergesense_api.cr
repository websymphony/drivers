module Vergesense; end

require "./models"

class Vergesense::VergesenseAPI < PlaceOS::Driver
  # Discovery Information
  descriptive_name "Vergesense API"
  generic_name :VergesenseAPI
  uri_base "https://api.vergesense.com"
  description "for more information visit: https://vergesense.readme.io/"

  default_settings({
    vergesense_api_key: "VS-API-KEY",
    uri_base:           "https://api.vergesense.com",
  })

  @api_key : String = ""
  @uri_base : String = ""
  @floors : Hash(String, Floor) = {} of String => Floor
  @debug_payload : Bool = false

  def on_load
    on_update
    init_sync
  end

  def on_update
    @api_key = setting(String, :vergesense_api_key)
    @uri_base = setting(String, :uri_base)
    @debug_payload = setting?(Bool, :debug_payload) || false
  end

  def init_sync
    begin
      buildings = Array(Building).from_json(get_request("/buildings"))
      if buildings
        buildings.not_nil!.each do |building|
          building_with_floors = BuildingWithFloors.from_json(get_request("/buildings/#{building.building_ref_id}"))
          if building_with_floors
            building_with_floors.floors.each do |floor|
              floor_key = "#{building.building_ref_id}-#{floor.floor_ref_id}".strip
              @floors[floor_key] = floor
            end
          end
        end

        spaces = Array(Space).from_json(get_request("/spaces"))
        spaces.each do |remote_space|
          update_spaces_state(remote_space)
        end
      end

      update_all_floors_status
    rescue e
      logger.error { "failed to perform initial vergesense API sync\n#{e.inspect_with_backtrace}" }
    end
  end

  EMPTY_HEADERS    = {} of String => String
  SUCCESS_RESPONSE = {HTTP::Status::OK, EMPTY_HEADERS, nil}

  # Webhook endpoint for space_report API, expects version 2
  def space_report_api(method : String, headers : Hash(String, Array(String)), body : String)
    logger.debug { "space_report API received: #{method},\nheaders #{headers},\nbody size #{body.size}" }
    logger.debug { body } if @debug_payload

    # Parse the data posted
    begin
      remote_space = Space.from_json(body)
      logger.debug { "parsed vergesense payload" }

      update_spaces_state(remote_space)
      update_single_floor_status(remote_space.floor_key, @floors[remote_space.floor_key]?)
    rescue e
      logger.error { "failed to parse vergesense space_report API payload\n#{e.inspect_with_backtrace}" }
      logger.debug { "failed payload body was\n#{body}" }
    end

    # Return a 200 response
    SUCCESS_RESPONSE
  end

  private def update_all_floors_status
    @floors.each do |floor_key, floor|
      update_single_floor_status(floor_key, floor)
    end
  end

  private def update_single_floor_status(floor_key, floor)
    if floor_key && floor
      self[floor_key] = floor.not_nil!.to_json
    end
  end

  private def update_spaces_state(remote_space)
    floor = @floors[remote_space.floor_key]?
    if floor
      floor_space = floor.spaces.find { |space| space.space_ref_id == remote_space.space_ref_id }
      if floor_space
        floor_space.building_ref_id = remote_space.building_ref_id
        floor_space.floor_ref_id = remote_space.floor_ref_id
        floor_space.people = remote_space.people
        floor_space.motion_detected = remote_space.motion_detected
        floor_space.timestamp = remote_space.timestamp
      end
    end
  end

  # Internal Helpers
  #############################################################################

  private def get_request(path)
    begin
      # TODO: Figure out how to use PlaceOS `get` instead
      # Driver doesn't terminate correctly when using `get`
      response = HTTP::Client.get(
        url: "#{@uri_base}#{path}",
        headers: headers
      )

      # response = get(
      #   path,
      #   headers: {"vs-api-key" => @api_key}
      # )

      if response.success?
        response.body
      else
        raise "unexpected response #{response.status_code}\n#{response.body}"
      end
    end
  end

  private def headers
    HTTP::Headers{
      "vs-api-key" => @api_key,
    }
  end
end
