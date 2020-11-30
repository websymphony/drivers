DriverSpecs.mock_driver "Vergesense::VergesenseAPI" do
  exec(:init_sync).get

  # expect_http_request do |request, response|
  #   case request.path
  #   when "/buildings"
  #     response.status_code = 200
  #     response << %([{"name": "HQ 1", "building_ref_id": "HQ1", "address": null}])
  #   end
  # end

  # status["HQ1"].should eq("HQ1")

  webhook_space_report_event = %({
  "building_ref_id": " 4_Embarcadero_Center",
  "floor_ref_id": "15_208",
  "space_ref_id": "1526",
  "sensor_ids": ["VS0-123", "VS1-321"],
  "person_count": 21,
  "signs_of_life": null,
  "motion_detected": true,
  "event_type": "space_report",
  "timestamp": "2019-08-21T21:10:25Z",
  "people": {
    "count": 21,
    "coordinates": [
      [
        [
          2.2673,
          4.3891
        ],
        [
          6.2573,
          1.5303
        ]
      ]
    ],
    "distances": {
      "units": "meters",
      "values": [1.5]
    }
  }
})

  exec(:space_report_api, method: "get", headers: {"test" => ["test"] }, body: webhook_space_report_event).get
end
