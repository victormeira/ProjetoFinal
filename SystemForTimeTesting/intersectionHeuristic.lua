--intersectionHeuristic returns the currentState and what time it should change to next one
function intersectionHeuristic (numberOfPassedCars, numberOfStoppedCars, numberOfPedestrians, nextSwitch, neighborIntersectionSwitch, currentState, currentTime, stateInterval)

  --time for a color switch
  if(nextSwitch < currentTime) then
    if currentState == "red" then
      currentState = "green"
      nextSwitch = currentTime + stateInterval
    elseif currentState == "yellow" then
      currentState = "red"
      nextSwitch = currentTime + stateInterval
    elseif currentState == "green" then
      currentState = "yellow"
      nextSwitch = currentTime + 2
    end

    return currentState, nextSwitch  
  end

  -- In case of yellow, do nothing
  if(currentState == "yellow") then
    return currentState, nextSwitch
  end

  if(nextSwitch > neighborIntersectionSwitch) then
    nextSwitch = neighborIntersectionSwitch - 2
  end

end

