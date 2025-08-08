extends Node

# Simple test script to verify our data classes work correctly
# Run this script to test the type-safe data structures

func _ready():
	print("Testing data classes...")
	
	test_pip_data()
	test_district_data()
	test_seat_data()
	test_voting_result()
	
	print("All data class tests completed!")

func test_pip_data():
	print("Testing PipData...")
	
	var pip = PipData.new()
	pip.id = "test_pip_1"
	pip.position = Vector2(100, 200)
	pip.set_random_party()
	
	assert(pip.is_valid())
	assert(pip.id == "test_pip_1")
	
	pip.vote()
	assert(pip.has_voted())
	assert(pip.vote_status == PipArea.VoteStatus.VOTED)
	
	var cloned_pip = pip.clone()
	assert(cloned_pip.id == pip.id)
	assert(cloned_pip.party == pip.party)
	
	print("  ✓ PipData tests passed")

func test_district_data():
	print("Testing DistrictData...")
	
	var district = DistrictData.new()
	district.id = "test_district_1"
	district.position = Vector2(50, 75)
	district.polygon_points = PackedVector2Array([Vector2(0, 0), Vector2(100, 0), Vector2(50, 100)])
	
	district.add_pip_id("pip_1")
	district.add_pip_id("pip_2")
	district.add_pip_id("pip_3")
	
	assert(district.is_valid())
	assert(district.get_pip_count() == 3)
	assert(district.has_pip("pip_2"))
	assert(district.get_area() > 0)
	
	district.remove_pip_id("pip_2")
	assert(district.get_pip_count() == 2)
	assert(not district.has_pip("pip_2"))
	
	var cloned_district = district.clone()
	assert(cloned_district.id == district.id)
	assert(cloned_district.get_pip_count() == district.get_pip_count())
	
	print("  ✓ DistrictData tests passed")

func test_seat_data():
	print("Testing SeatData...")
	
	var seat = SeatData.new()
	seat.seat_index = 0
	
	assert(seat.is_valid())
	assert(not seat.is_assigned())
	
	var district = DistrictData.new()
	district.id = "test_district"
	district.winning_party = PipArea.Party.GREEN
	
	seat.assign_to_district(district)
	assert(seat.is_assigned())
	assert(seat.district_id == "test_district")
	assert(seat.assigned_party == PipArea.Party.GREEN)
	
	seat.set_voting_state(true)
	assert(seat.is_voting)
	
	seat.clear_assignment()
	assert(not seat.is_assigned())
	assert(seat.assigned_party == PipArea.Party.NONE)
	
	print("  ✓ SeatData tests passed")

func test_voting_result():
	print("Testing VotingResult...")
	
	var result = VotingResult.new()
	result.district_id = "test_district"
	result.set_vote_counts(15, 12, 30)
	
	assert(result.is_valid())
	assert(result.get_total_votes() == 27)
	assert(result.winning_party == PipArea.Party.GREEN)
	assert(result.get_vote_margin() == 3)
	assert(result.turnout_percentage == 90.0)
	assert(not result.is_tie())
	
	# Test tie scenario
	var tie_result = VotingResult.new()
	tie_result.district_id = "tie_district"
	tie_result.set_vote_counts(10, 10, 25)
	
	assert(tie_result.is_tie())
	assert(tie_result.winning_party == PipArea.Party.NONE)
	assert(tie_result.get_vote_margin() == 0)
	assert(tie_result.turnout_percentage == 80.0)
	
	print("  ✓ VotingResult tests passed")