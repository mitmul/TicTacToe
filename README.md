TicTacToe
=================
checked environment: OSX(10.8.3), Ruby 1.9.3-p392

## Required gems
- Ruby/SDL (with SGE)
- NArray

## Other requirements
- rsdl(OSX)

## Preparation
### Install SDL & SGE
```
$ brew install sdl sdl_image sdl_ttf sdl_sound
$ brew install https://gist.github.com/mitmul/5410467/raw/c4fa716635e951b61f489726976b10f00dd41306/sge.rb
```

### Install Gems
```
$ gem install rubysdl
$ gem install rsdl
$ gem install narray
```
***NOTICE:*** rsdl gem cannot be installed on Ruby 2.0.0-p0

## Usage
### Start 
```
$ rsdl tictactoe.rb
```

### Play
- Click an empty cell you want
- The agent makes a move and show values of the state-action value function on all cells