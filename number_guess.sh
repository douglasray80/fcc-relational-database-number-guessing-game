#!/bin/bash

# Program that generates a random number between 1 and 1000 for users to guess

PSQL="psql -X --username=freecodecamp --dbname=number_guess --no-align --tuples-only -c"

echo "Enter your username:"
read USERNAME

# get user details
USER_DETAILS=$($PSQL "SELECT * FROM users WHERE username = '$USERNAME'")
# if username doesn't exist in db
if [[ -z $USER_DETAILS ]]
then
  # create new user
  INSERT_USERNAME_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  # print message
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # parse query result
  echo "$USER_DETAILS" | while IFS='|' read USER GAMES_PLAYED BEST_GAME
  do
    # print message
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# initialise number_of_guesses variable
NUMBER_OF_GUESSES=0

# upon game completion, update user's info (games_played, best_game)
UPDATE_USER() {
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username = '$USERNAME'")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username = '$USERNAME'")
  if [[ -z $BEST_GAME ]] || [[ $1 -lt $BEST_GAME ]]
  then
    UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $1 WHERE username = '$USERNAME'")
  fi
  UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = $(echo $GAMES_PLAYED + 1) WHERE username = '$USERNAME'")
}

# game logic
GET_USER_GUESS() {
  # if args, print
  if [[ $1 ]]
  then
    echo -e "\n$1"
  else
    echo "Guess the secret number between 1 and 1000:"
  fi
  read NUMBER_INPUT
  # if input is not an integer print message
  if [[ ! $NUMBER_INPUT =~ ^[0-9]+$ ]]
  then
    # ask for input again
    GET_USER_GUESS "That is not an integer, guess again:"
  fi
  # if guess is less than secret number
  if (( NUMBER_INPUT < SECRET_NUMBER ))
  then
    # increment number_of_guesses
    (( NUMBER_OF_GUESSES++ ))
    GET_USER_GUESS "It's higher than that, guess again:"
  elif (( NUMBER_INPUT > SECRET_NUMBER ))
  then
    # increment number_of_guesses
    (( NUMBER_OF_GUESSES++ ))
    GET_USER_GUESS "It's lower than that, guess again:"
  else
    # increment number_of_guesses
    (( NUMBER_OF_GUESSES++ ))
    UPDATE_USER $NUMBER_OF_GUESSES
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    exit
  fi
}

# start game
GET_USER_GUESS
