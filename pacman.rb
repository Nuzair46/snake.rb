require 'curses'

class PacManGame
  PACMAN_CHAR = 'C'
  GHOST_CHAR = 'G'
  WALL_CHAR = '#'
  PELLET_CHAR = '.'
  EMPTY_CHAR = ' '
  SCORE_POSITION = 0

  def initialize
    @screen = Curses.init_screen
    Curses.start_color
    Curses.curs_set(0)
    Curses.noecho
    Curses.cbreak
    @screen.keypad(true)
    Curses.timeout = 100 # Timeout interval for smoother movement

    init_colors

    @maze = [
      "############################",
      "#............##............#",
      "#.####.#####.##.#####.####.#",
      "#.####.#####.##.#####.####.#",
      "#.####.#####.##.#####.####.#",
      "#..........................#",
      "#.####.##.########.##.####.#",
      "#.####.##.########.##.####.#",
      "#......##....##....##......#",
      "######.##### ## #####.######",
      "######.##### ## #####.######",
      "######.##          ##.######",
      "######.## ######## ##.######",
      "######.## ######## ##.######",
      "#............##............#",
      "#.####.#####.##.#####.####.#",
      "#.####.#####.##.#####.####.#",
      "#.####.##..........##.####.#",
      "#.####.##.########.##.####.#",
      "#...........##.............#",
      "############################"
    ]

    @pacman = { y: 1, x: 1 }
    @ghosts = [{ y: 11, x: 11, direction: [1, 0] }, { y: 11, x: 12, direction: [-1, 0] }]
    @score = 0
    @game_over = false
    @win = false
  end

  def init_colors
    Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
    Curses.init_pair(3, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.init_pair(4, Curses::COLOR_RED, Curses::COLOR_BLACK)
  end

  def play
    loop do
      handle_input
      update_game unless @game_over
      draw
      break if @game_over
    end

    show_game_over
  ensure
    Curses.close_screen
  end

  def handle_input
    case @screen.getch
    when Curses::Key::UP
      move_pacman(-1, 0)
    when Curses::Key::DOWN
      move_pacman(1, 0)
    when Curses::Key::LEFT
      move_pacman(0, -1)
    when Curses::Key::RIGHT
      move_pacman(0, 1)
    when 'q'
      exit
    end
  end

  def move_pacman(dy, dx)
    new_y = @pacman[:y] + dy
    new_x = @pacman[:x] + dx

    if @maze[new_y][new_x] != WALL_CHAR
      @pacman[:y] = new_y
      @pacman[:x] = new_x

      if @maze[new_y][new_x] == PELLET_CHAR
        @score += 10
        @maze[new_y][new_x] = EMPTY_CHAR
      end

      check_collision_with_ghosts
    end
  end

  def update_game
    move_ghosts
    check_collision_with_ghosts
    check_win_condition
  end

  def move_ghosts
    @ghosts.each do |ghost|
      new_y = ghost[:y] + ghost[:direction][0]
      new_x = ghost[:x] + ghost[:direction][1]

      if @maze[new_y][new_x] == WALL_CHAR
        change_ghost_direction(ghost)
      else
        ghost[:y] = new_y
        ghost[:x] = new_x
      end
    end
  end

  def change_ghost_direction(ghost)
    possible_directions = [[1, 0], [-1, 0], [0, 1], [0, -1]].reject { |dir| dir == [-ghost[:direction][0], -ghost[:direction][1]] }
    ghost[:direction] = possible_directions.sample
  end

  def check_win_condition
    unless pellets_remaining?
      @game_over = true
      @win = true
    end
  end

  def check_collision_with_ghosts
    @ghosts.each do |ghost|
      if @pacman[:y] == ghost[:y] && @pacman[:x] == ghost[:x]
        @game_over = true
      end
    end
  end

  def pellets_remaining?
    @maze.any? { |row| row.include?(PELLET_CHAR) }
  end

  def draw
    @screen.clear

    # Draw maze
    @maze.each_with_index do |row, y|
      @screen.setpos(y, 0)
      @screen.addstr(row)
    end

    # Draw Pac-Man
    Curses.attron(Curses.color_pair(2))
    @screen.setpos(@pacman[:y], @pacman[:x])
    @screen.addch(PACMAN_CHAR)
    Curses.attroff(Curses.color_pair(2))

    # Draw Ghosts
    Curses.attron(Curses.color_pair(4))
    @ghosts.each do |ghost|
      @screen.setpos(ghost[:y], ghost[:x])
      @screen.addch(GHOST_CHAR)
    end
    Curses.attroff(Curses.color_pair(4))

    # Draw score
    @screen.setpos(SCORE_POSITION, 0)
    @screen.addstr("Score: #{@score}")

    @screen.refresh
  end

  def show_game_over
    if @win
      @screen.setpos(@screen.maxy / 2, @screen.maxx / 2 - 5)
      @screen.addstr("You Won!")
    else
      @screen.setpos(@screen.maxy / 2, @screen.maxx / 2 - 5)
      @screen.addstr("Game Over!")
    end
    @screen.refresh

    loop do
      case @screen.getch
      when 'q'
        exit
      end
    end
  end
end

PacManGame.new.play
