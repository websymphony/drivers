DriverSpecs.mock_driver "Place::StaffAPI" do
  settings({
    # PlaceOS API creds, so we can query the zone metadata
    username:     "",
    password:     "",
    client_id:    "",
    redirect_uri: "",

    running_a_spec: true,
  })

  resp = exec(:query_bookings, "desk")

  expect_http_request do |request, response|
    headers = request.headers
    if headers["Authorization"]? == "spec-test"
      response.status_code = 200
      response << %([{
        "id": 1234,
        "user_id": "user-12345",
        "user_email": "steve@place.tech",
        "user_name": "Steve T",
        "asset_id": "desk-2-12",
        "zones": ["zone-build1", "zone-level2"],
        "booking_type": "Steve T",
        "booking_start": 123456,
        "booking_end": 12345678,
        "timezone": "Australia/Sydney",
        "checked_in": true,
        "rejected": false,
        "approved": false
      },{
        "id": 5678,
        "user_id": "user-67890",
        "user_email": "bob@place.tech",
        "user_name": "Bob T",
        "asset_id": "desk-2-13",
        "zones": ["zone-build1", "zone-level2"],
        "booking_type": "Bob T",
        "booking_start": 123456,
        "booking_end": 12345678,
        "timezone": "NewZealand/Queenstown",
        "checked_in": false,
        "rejected": true,
        "approved": false
      }])
    else
      response.status_code = 401
    end
  end

  resp.get.should eq(JSON.parse(%({
    "steve@place.tech": [{
      "id": 1234,
      "user_id": "user-12345",
      "user_email": "steve@place.tech",
      "user_name": "Steve T",
      "asset_id": "desk-2-12",
      "zones": ["zone-build1", "zone-level2"],
      "booking_type": "Steve T",
      "booking_start": 123456,
      "booking_end": 12345678,
      "timezone": "Australia/Sydney",
      "checked_in": true,
      "rejected": false,
      "approved": false
    }]
  })))
end
