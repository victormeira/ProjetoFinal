#!/bin/bash 
NUMBER_OF_INTS=1000
lua manager.lua &
for ((i = 0 ; i <= $NUMBER_OF_INTS ; i++)); do
  lua intersection.lua $i $NUMBER_OF_INTS &
done