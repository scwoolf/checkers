class Piece
  
  attr_accessor :pos, :color, :king
  
  def initialize(board, pos, color, king = false)
    @board, @pos, @color, @king = board, pos, color, king
    @board[@pos] = self
  end

	def perform_slide(end_pos)
    delta, directions, result = [end_pos[0] - @pos[0], end_pos[1] - @pos[1]], move_diffs, false
    if on_board?(end_pos) && is_empty?(end_pos) && directions.include?(delta)
      @board[end_pos], @board[@pos], @pos, result = self, nil, end_pos, true
    end
    result
  end
	
	def perform_jump(end_pos)
    delta = [(end_pos[0] - @pos[0])/2, (end_pos[1] - @pos[1])/2]
    middle_pos, directions, result = [@pos[0] + delta[0], @pos[1] + delta[1]], move_diffs, false 
    if on_board?(end_pos) && is_empty?(end_pos) && enemy_between?(end_pos) && directions.include?(delta)
      @board[end_pos], @board[@pos], @board[middle_pos], @pos, result = self, nil, nil, end_pos, true
    end
    result
	end
	
	def move_diffs
    return [[-1,1], [1,1], [1,-1], [-1,-1]] if @king 
    @color == "white" ? [[-1,1], [1,1]] : [[-1,-1], [1,-1]]
	end
    
  def is_empty?(end_pos)
    !@board[end_pos]
  end
  
  def on_board?(end_pos)
    end_pos[0].between?(1,8) && end_pos[1].between?(1,8)
  end
  
  def enemy_between?(end_pos)
    middle_pos = [(@pos[0] + end_pos[0]) / 2, (@pos[1] + end_pos[1]) / 2] 
    @board[middle_pos] && @board[middle_pos].color != @color
  end
    
	def maybe_promote
    (@pos[1] == 8 && color == "white") || (@pos[1] == 1 && color == "black")
	end 

	def perform_moves(move_seq)
    raise "Invalid move!" unless valid_moves_sequence?(move_seq)
    perform_moves!(move_seq)
	end
	
	def perform_moves!(move_seq)
    if move_seq.length == 1
      raise InvalidMoveError.new "Invalid Move" unless (perform_slide(move_seq.flatten) || perform_jump(move_seq.flatten))
    else
      move_seq.each do |move|
        raise InvalidMoveError.new "Invalid Sequence" unless perform_jump(move)
      end
    end
    true 
	end
	
	def valid_moves_sequence?(move_seq)
    dup_board = @board.dup
    begin
      dup_board[@pos].perform_moves!(move_seq)
    rescue InvalidMoveError
      result = false
    else
      result = true
    end
    result
	end
  
  def promote
    @king = true
  end
  
  def inspect
    return "○" if @color == "white" && !@king
    return "●" if @color == "black" && !@king
    return "♔" if @color == "white" && @king
    return "♚" if @color == "black" && @king
  end
end

class Board
  
  attr_accessor :coords
  
  def initialize
    @grid = Array.new(8) { Array.new(8) }
    @coords = (1..8).to_a.product((1..8).to_a)
  end
  
  def [](pos)
    x,y = pos
    @grid[8-y][x-1]
  end
  
  def []=(pos, obj)
    x,y = pos
    @grid[8-y][x-1] = obj
  end
  
  def dup
    dup_board = Board.new
    @coords.each do |pos| 
      dup_board[pos] = Piece.new(dup_board, self[pos].pos, self[pos].color, self[pos].king) if self[pos]
    end
    dup_board
  end
  
  def won?(color) 
    @coords.each do |pos|
      return false if self[pos] && self[pos].color != color
    end
    true
  end
    
  def render
    @grid.each_with_index do |row, ridx|
      y = 8 - ridx
      row_str = "#{y} |"
      row.each do |el|
        row_str += "_ |" unless el
        row_str += el.inspect + " |" if el
      end
      puts row_str
    end
    puts "   1  2  3  4  5  6  7  8"    
  end
  
end
 
class Game
  
  def initialize
    @board = Board.new
    @board.coords.each do |pos|
      x,y = pos
      @board[pos] = Piece.new(@board, pos, "white") if y <= 3 && (x+y).even?
      @board[pos] = Piece.new(@board, pos, "black") if y >= 6 && (x+y).even?
    end
  end
  
  def play
    puts "Welcome to Checkers!"
    current_player = "white"
    loop do
      @board.render
      puts "The current player is #{current_player}. Select x and y of piece, separated by a space."
      piece_position = gets.chomp.split(' ').map(&:to_i)
      next if !@board[piece_position] || @board[piece_position].color != current_player
      selected_piece = @board[piece_position]
      puts "Where would you like to move? Select x and y of locations, separated by a space."
      puts "You may move more than once. Enclose each location in brackets and separate by a space."
      sequence_string = gets.chomp
      move_sequence = process_sequence_string(sequence_string)
      selected_piece.perform_moves(move_sequence)
      break if @board.won?(current_player)
      selected_piece.promote if selected_piece.maybe_promote
      current_player = switch_player(current_player) 
    end
    puts "The winner is #{current_player}!"
  end
    
  def switch_player(player)
    player == "white" ? "black" : "white"
  end
  
  def process_sequence_string(seq_str)
    pos_str_array, move_seq = (seq_str.length == 3 ? 
    [seq_str] : seq_str[1...seq_str.length - 1].split('] [')), []
    pos_str_array.each do |pos|
      move_seq << pos.split(' ').map(&:to_i)
    end
    move_seq
  end
  
  def inspect
  end
    
end