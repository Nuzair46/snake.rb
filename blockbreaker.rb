require 'curses'

class BlockBreakingGame
  PADDLE_CHAR = '='
  BALL_CHAR = 'O'
  BRICK_CHAR = '#'
  SCORE_POSITION = 1

  def initialize
    @screen = Curses.init_screen
    Curses.start_color
    Curses.curs_set(0)
    Curses.noecho
    Curses.cbreak
    @screen.keypad(true)
    Curses.timeout = 30 # Increase timeout interval for smoother movement

    init_colors

    @paddle = { y: @screen.maxy - 2, x: @screen.maxx / 2, width: 20 }
    @ball = { y: @screen.maxy - 3, x: @screen.maxx / 2, direction: [-1, -1] }
    @bricks = generate_bricks
    @score = 0
    @game_over = false
    @ball_move_counter = 0 # Counter to slow down ball movement
  end

  def init_colors
    Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_RED, Curses::COLOR_BLACK)
  end

  def generate_bricks
    bricks = []
    5.times do |row|
      10.times do |col|
        bricks << { y: row + 2, x: col * 12 + 2 }
      end
    end
    bricks
  end

  def play
    loop do
      handle_input
      if @ball_move_counter % 3 == 0 # Move ball every 3rd loop iteration
        move_ball unless @game_over
      end
      @ball_move_counter += 1
      check_collisions
      draw
    end

    show_game_over
  ensure
    Curses.close_screen
  end

  def handle_input
    case @screen.getch
    when 'a'
      @paddle[:x] -= 2 if @paddle[:x] > 0
    when 'd'
      @paddle[:x] += 2 if @paddle[:x] < @screen.maxx - @paddle[:width]
    when 'q'
      exit
    when 'r'
      reset_game if @game_over
    end
  end

  def move_ball
    @ball[:y] += @ball[:direction][0]
    @ball[:x] += @ball[:direction][1]
  end

  def check_collisions
    # Ball collision with top
    if @ball[:y] <= 0
      @ball[:direction][0] = -@ball[:direction][0]
    end

    # Ball collision with walls
    if @ball[:x] <= 0 || @ball[:x] >= @screen.maxx - 1
      @ball[:direction][1] = -@ball[:direction][1]
    end

    # Ball collision with paddle
    if @ball[:y] == @paddle[:y] - 1 && (@paddle[:x]..@paddle[:x] + @paddle[:width]).include?(@ball[:x])
      @ball[:direction][0] = -@ball[:direction][0]
    end

    # Ball collision with bricks
    @bricks.each do |brick|
      if @ball[:y] == brick[:y] && @ball[:x] == brick[:x]
        @ball[:direction][0] = -@ball[:direction][0]
        @bricks.delete(brick)
        @score += 10
        break
      end
    end

    # Ball out of bounds
    if @ball[:y] >= @screen.maxy - 1
      @game_over = true
    end
  end

  def draw
    @screen.clear

    # Draw paddle
    Curses.attron(Curses.color_pair(2))
    @paddle[:width].times do |i|
      @screen.setpos(@paddle[:y], @paddle[:x] + i)
      @screen.addch(PADDLE_CHAR)
    end
    Curses.attroff(Curses.color_pair(2))

    # Draw ball
    Curses.attron(Curses.color_pair(3))
    @screen.setpos(@ball[:y], @ball[:x])
    @screen.addch(BALL_CHAR)
    Curses.attroff(Curses.color_pair(3))

    # Draw bricks
    Curses.attron(Curses.color_pair(1))
    @bricks.each do |brick|
      @screen.setpos(brick[:y], brick[:x])
      @screen.addch(BRICK_CHAR)
    end
    Curses.attroff(Curses.color_pair(1))

    # Draw score
    @screen.setpos(SCORE_POSITION, 2)
    @screen.addstr("Score: #{@score}")

    @screen.refresh
  end

  def show_game_over
    @screen.setpos(@screen.maxy / 2, @screen.maxx / 2 - 5)
    @screen.addstr("Game Over!")
    @screen.setpos(@screen.maxy / 2 + 1, @screen.maxx / 2 - 10)
    @screen.addstr("Press 'r' to restart or 'q' to quit.")
    @screen.refresh

    loop do
      case @screen.getch
      when 'r'
        reset_game
        break
      when 'q'
        exit
      end
    end
  end

  def reset_game
    @paddle[:x] = @screen.maxx / 2
    @ball = { y: @screen.maxy - 3, x: @screen.maxx / 2, direction: [-1, -1] }
    @bricks = generate_bricks
    @score = 0
    @game_over = false
    @ball_move_counter = 0
  end
end

BlockBreakingGame.new.play
