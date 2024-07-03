require 'curses'

class SnakeGame
  SCREEN_TIMEOUT = 100
  BIG_FOOD_TIMER = 200
  BIG_FOOD_RANDOM_MAX = 4

  UP = Curses::Key::UP
  DOWN = Curses::Key::DOWN
  LEFT = Curses::Key::LEFT
  RIGHT = Curses::Key::RIGHT
  QUIT = ['q', 'Q']
  RESTART = ['k', 'K']
  
  # The following needs to be in single characters for it to work
  FOOD_SYMBOL = '*'
  BIG_FOOD_SYMBOL = 'X'
  SNAKE_HEAD_SYMBOL = '@'
  SNAKE_BODY_SYMBOL = '#'

  def initialize
    @screen = Curses.init_screen
    Curses.curs_set(0)
    @screen.keypad(true)
    @screen.timeout = SCREEN_TIMEOUT
    @high_score = 0
    @direction_list = [:up, :down, :left, :right]
    Curses.start_color
    Curses.use_default_colors
    init_colors
  end

  def init_colors
    Curses.init_pair(1, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_RED, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
    Curses.init_pair(5, Curses::COLOR_RED, Curses::COLOR_BLACK)
  end

  def launch
    maxx = @screen.maxx
    maxy = @screen.maxy
    start_x = rand(10..maxy-10)
    start_y = rand(10..maxx-10)
    @snake = [[start_x, start_y], [start_x, start_y - 1], [start_x, start_y - 2]]

    @direction = @direction_list.sample
    @food = [10, 10]
    @big_food = nil
    @big_food_timer = 0
    @score = 0
    @game_over = false
    place_food
    play
  end

  def play
    loop do
      if @game_over
        show_game_over
        handle_game_over_input
        break unless @game_over
      end
      
      handle_input
      move_snake
      check_collisions
      tick_big_food_timer
      draw
    end
  end

  def quit!
    @game_over = true
    Curses.close_screen
    exit
  end

  def place_food
    @food = [rand(1..(@screen.maxy - 1)), rand(1..(@screen.maxx - 1))]
    place_big_food if rand(1..BIG_FOOD_RANDOM_MAX) == 1 && @big_food_timer <= 0
  end

  def place_big_food
    @big_food = [rand(1..(@screen.maxy - 3)), rand(1..(@screen.maxx - 3))]
    @big_food_timer = BIG_FOOD_TIMER
  end

  def handle_input
    case @screen.getch
    when UP
      @direction = :up if @direction != :down
    when DOWN
      @direction = :down if @direction != :up
    when LEFT
      @direction = :left if @direction != :right
    when RIGHT
      @direction = :right if @direction != :left
    when *QUIT
      quit!
    end
  end

  def move_snake
    return if @game_over

    head = @snake.first.dup

    case @direction
    when :up
      head[0] -= 1
    when :down
      head[0] += 1
    when :left
      head[1] -= 1
    when :right
      head[1] += 1
    end

    @snake.unshift(head)

    if head == @food
      grow_snake
      place_food
    elsif @big_food && (@big_food[0]..@big_food[0] + 2).include?(head[0]) && (@big_food[1]..@big_food[1] + 2).include?(head[1])
      grow_snake(10)
      @big_food = nil
    else
      @snake.pop
    end
  end

  def grow_snake(size = 1)
    @score += size
    @high_score = @score if @score > @high_score
    size.times do
      @snake.push(@snake.last.dup)
    end
  end

  def tick_big_food_timer
    return unless @big_food

    @big_food_timer -= 1
    if @big_food_timer.zero?
      @big_food = nil
    end
  end

  def check_collisions
    head = @snake.first
    if head[0] <= 0 || head[0] >= @screen.maxy || head[1] <= 0 || head[1] >= @screen.maxx || @snake[1..-1].include?(head)
      @game_over = true
    end
  end

  def show_game_over
    @high_score = @score if @score > @high_score
    sleep(2)
    @screen.clear
    @screen.attron(Curses.color_pair(5) | Curses::A_BOLD)
    @screen.setpos(@screen.maxy / 2, (@screen.maxx - 10) / 2)
    @screen.addstr("Game Over")
    @screen.setpos(@screen.maxy / 2 + 1, (@screen.maxx - 16) / 2)
    @screen.addstr("Your score: #{@score}")
    @screen.setpos(@screen.maxy / 2 + 2, (@screen.maxx - 16) / 2)
    @screen.addstr("High score: #{@high_score}")
    @screen.setpos(@screen.maxy / 2 + 3, (@screen.maxx - 32) / 2)
    @screen.addstr("Press K to play again or Q to quit")
    @screen.attroff(Curses.color_pair(5) | Curses::A_BOLD)
    @screen.refresh
  end

  def handle_game_over_input
    loop do
      case @screen.getch
      when *RESTART
        launch
        break
      when *QUIT
        quit!
      end
    end
  end

  def draw
    @screen.clear
    @screen.setpos(0, (@screen.maxx - 10) / 2 - 10)
    @screen.attron(Curses.color_pair(5) | Curses::A_BOLD)
    @screen.addstr("Score: #{@score}")

    @screen.setpos(0, (@screen.maxx - 10) / 2 + 10)
    @screen.addstr("High Score: #{@high_score}")
    @screen.attroff(Curses.color_pair(5) | Curses::A_BOLD)
    @screen.attron(Curses.color_pair(3))
    @screen.setpos(@food[0], @food[1])
    @screen.addch(FOOD_SYMBOL)
    @screen.attroff(Curses.color_pair(3))

    if @big_food
      @screen.attron(Curses.color_pair(4))
      (@big_food[0]..@big_food[0] + 2).each do |row|
        (@big_food[1]..@big_food[1] + 2).each do |col|
          @screen.setpos(row, col)
          @screen.addch(BIG_FOOD_SYMBOL)
        end
      end
      @screen.attroff(Curses.color_pair(4))
    end

    @snake.each_with_index do |segment, index|
      if index.zero?
        @screen.attron(Curses.color_pair(1) | Curses::A_BOLD)
        @screen.setpos(segment[0], segment[1])
        @screen.addch(SNAKE_HEAD_SYMBOL)
        @screen.attroff(Curses.color_pair(1) | Curses::A_BOLD)
      else
        @screen.attron(Curses.color_pair(2) | Curses::A_BOLD)
        @screen.setpos(segment[0], segment[1])
        @screen.addch(SNAKE_BODY_SYMBOL)
        @screen.attroff(Curses.color_pair(2) | Curses::A_BOLD)
      end
    end

    @screen.refresh
  end
end

SnakeGame.new.launch
