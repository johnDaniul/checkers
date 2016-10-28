//
//  ViewController.m
//  checkers
//
//  Created by John Daniul on 3/18/16.
//  Copyright © 2016 John. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <stdlib.h>

NSString *const RED = @"RED";
NSString *const BLACK = @"BLK";
NSString *const EMPTY = @"[ ]";

// Storage for move data
@interface Move : NSObject

@property NSString *player;
@property NSInteger startingIndex;
@property NSInteger endingIndex;
@property BOOL isJump;
@property NSInteger capturedIndex;

@end

@implementation Move

- (BOOL)isEqual:(id)object {
    BOOL isEqual = YES;
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (![self.player isEqualToString:((Move *)object).player]) {
        isEqual = NO;
    }
    
    if (self.startingIndex != ((Move *)object).startingIndex) {
        isEqual = NO;
    }
    
    if (self.endingIndex != ((Move *)object).endingIndex) {
        isEqual = NO;
    }
    
    if (self.capturedIndex != ((Move *)object).capturedIndex) {
        isEqual = NO;
    }
    
    if (self.isJump != ((Move *)object).isJump) {
        isEqual = NO;
    }
    
    return isEqual;
}

@end


@interface ViewController ()

@property(weak, nonatomic) IBOutlet UIView *checkerBoard;
@property(nonatomic) NSMutableArray *gameBoardData;

@end


@implementation ViewController {
    NSMutableArray *_playableSquares;
    NSMutableArray *_blackCheckerViews;
    NSMutableArray *_redCheckerViews;
    NSInteger _blackPieces;
    NSInteger _redPieces;
    
    // Move tracking
    NSString *_currentPlayer;
    NSArray *_validMoves;
    NSInteger _startingIndex;
    UIView *_currentCheckerView;
    CGPoint _currentCheckerOriginalLocation;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self layoutCheckersBoard];
    [self startNewGame];
}

#pragma mark Core Gameplay

- (void)startNewGame {
    [self cleanupViews];
    [self initializeGameData];
    [self createCheckers];
    [self beginNextTurn];
}

- (void)initializeGameData {
    self.gameBoardData = [@[EMPTY, BLACK, EMPTY, BLACK, EMPTY, BLACK, EMPTY, BLACK,
                            BLACK, EMPTY, BLACK, EMPTY, BLACK, EMPTY, BLACK, EMPTY,
                            EMPTY, BLACK, EMPTY, BLACK, EMPTY, BLACK, EMPTY, BLACK,
                            EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
                            EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY,
                            RED, EMPTY, RED, EMPTY, RED, EMPTY, RED, EMPTY,
                            EMPTY, RED, EMPTY, RED, EMPTY, RED, EMPTY, RED,
                            RED, EMPTY, RED, EMPTY, RED, EMPTY, RED, EMPTY] mutableCopy];
    _blackPieces = 12;
    _redPieces = 12;
    
    _currentPlayer = EMPTY;
}

- (void)cleanupViews {
    for (UIView *checker in _redCheckerViews) {
        [checker removeFromSuperview];
    }
    [_redCheckerViews removeAllObjects];
    
    for (UIView *checker in _blackCheckerViews) {
        [checker removeFromSuperview];
    }
    [_blackCheckerViews removeAllObjects];
}

- (void)beginNextTurn {
    if ([_currentPlayer isEqualToString:RED]) {
        _currentPlayer = BLACK;
    } else {
        _currentPlayer = RED;
    }
    
    self.checkerBoard.userInteractionEnabled = NO;
    
    _validMoves = [self getValidMovesForPlayer:_currentPlayer];
    
    if ([self isGameOver]) {
        [self handleGameOver];
        return;
    }
    
    if ([_currentPlayer isEqualToString:RED]) {
        self.checkerBoard.userInteractionEnabled = YES;
    } else {
        [self performSelector:@selector(performAITurn) withObject:nil afterDelay:0.5f];
    }
}

- (void)performAITurn {
    int randomMove = arc4random_uniform((int)_validMoves.count - 1);
    [self makeMove:_validMoves[randomMove]];
}

- (BOOL)isGameOver {
    if (_blackPieces == 0 || _redPieces == 0 || _validMoves.count == 0) {
        return YES;
    }
    
    return NO;
}

- (void)checkForFollowUpJumpsFromMove:(Move *)move {
    NSMutableArray *validJumps = [@[] mutableCopy];
    
    NSInteger jumpLeftOffset = -18;
    NSInteger jumpRightOffset = -14;
    
    if ([move.player isEqualToString:BLACK]) {
        jumpLeftOffset = 18;
        jumpRightOffset = 14;
    }
    
    Move *jumpLeft = [[Move alloc] init];
    jumpLeft.player = move.player;
    jumpLeft.isJump = YES;
    jumpLeft.capturedIndex = move.endingIndex + (jumpLeftOffset / 2);
    jumpLeft.startingIndex = move.endingIndex;
    jumpLeft.endingIndex = move.endingIndex + jumpLeftOffset;
    
    if ([self isMoveValid:jumpLeft]) {
        [validJumps addObject:jumpLeft];
    }
    
    Move *jumpRight = [[Move alloc] init];
    jumpRight.player = move.player;
    jumpRight.isJump = YES;
    jumpRight.capturedIndex = move.endingIndex + (jumpRightOffset / 2);
    jumpRight.startingIndex = move.endingIndex;
    jumpRight.endingIndex = move.endingIndex + jumpRightOffset;
    
    if ([self isMoveValid:jumpRight]) {
        [validJumps addObject:jumpRight];
    }
    
    _validMoves = validJumps;
    
    if (validJumps.count > 0) {
        if ([move.player isEqualToString:RED]) {
            self.checkerBoard.userInteractionEnabled = YES;
        } else {
            [self performSelector:@selector(performAITurn) withObject:nil afterDelay:0.5f];
        }
    } else {
        [self performSelector:@selector(beginNextTurn) withObject:nil afterDelay:0.25f];
    }
}

- (void)makeMove:(Move *)move {
    self.gameBoardData[move.startingIndex] = EMPTY;
    self.gameBoardData[move.endingIndex] = move.player;
    if (move.isJump) {
        self.gameBoardData[move.capturedIndex] = EMPTY;
        
        if ([move.player isEqualToString:RED]) {
            _blackPieces--;
        } else {
            _redPieces--;
        }
        
        [self updateGameboardOnMove:move];
        
        [self performSelector:@selector(checkForFollowUpJumpsFromMove:) withObject:move afterDelay:0.15f];
    } else {
        [self updateGameboardOnMove:move];
        
        [self performSelector:@selector(beginNextTurn) withObject:nil afterDelay:0.15f];
    }
    
    // Console output of gameboard
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[0], _gameBoardData[1], _gameBoardData[2], _gameBoardData[3], _gameBoardData[4], _gameBoardData[5], _gameBoardData[6], _gameBoardData[7]);
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[8], _gameBoardData[9], _gameBoardData[10], _gameBoardData[11], _gameBoardData[12], _gameBoardData[13], _gameBoardData[14], _gameBoardData[15]);
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[16], _gameBoardData[17], _gameBoardData[18], _gameBoardData[19], _gameBoardData[20], _gameBoardData[21], _gameBoardData[22], _gameBoardData[23]);
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[24], _gameBoardData[25], _gameBoardData[26], _gameBoardData[27], _gameBoardData[28], _gameBoardData[29], _gameBoardData[30], _gameBoardData[31]);
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[32], _gameBoardData[33], _gameBoardData[34], _gameBoardData[35], _gameBoardData[36], _gameBoardData[37], _gameBoardData[38], _gameBoardData[39]);
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[40], _gameBoardData[41], _gameBoardData[42], _gameBoardData[43], _gameBoardData[44], _gameBoardData[45], _gameBoardData[46], _gameBoardData[47]);
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[48], _gameBoardData[49], _gameBoardData[50], _gameBoardData[51], _gameBoardData[52], _gameBoardData[53], _gameBoardData[54], _gameBoardData[55]);
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@", _gameBoardData[56], _gameBoardData[57], _gameBoardData[58], _gameBoardData[59], _gameBoardData[60], _gameBoardData[61], _gameBoardData[62], _gameBoardData[63]);
    NSLog(@"\n");
}

- (void)handleGameOver {
    NSString *message;
    
    if (_blackPieces == _redPieces) {
        message = @"Stalemate!";
    } else if (_redPieces > _blackPieces) {
        message = @"You win!";
    } else {
        message = @"You Lose!";
    }
    
    UIAlertController *gameOver = [UIAlertController alertControllerWithTitle:@"Game Over" message:message preferredStyle:UIAlertControllerStyleAlert];
    [gameOver addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self startNewGame];
    }]];
    
    [self presentViewController:gameOver animated:YES completion:nil];
}

- (NSArray *)getValidMovesForPlayer:(NSString *)player {
    NSMutableArray *validJumps = [@[] mutableCopy];
    NSMutableArray *validSlides = [@[] mutableCopy];
    
    NSInteger jumpLeftOffset = -18;
    NSInteger jumpRightOffset = -14;
    NSInteger slideLeftOffset = -9;
    NSInteger slideRightOffset = -7;
    
    if ([player isEqualToString:BLACK]) {
        jumpLeftOffset = 18;
        jumpRightOffset = 14;
        slideLeftOffset = 9;
        slideRightOffset = 7;
    }
    
    NSInteger index = 0;
    for (NSString *checker in self.gameBoardData) {
        if ([checker isEqualToString:player]) {
            Move *jumpLeft = [[Move alloc] init];
            jumpLeft.player = player;
            jumpLeft.isJump = YES;
            jumpLeft.capturedIndex = index + slideLeftOffset;
            jumpLeft.startingIndex = index;
            jumpLeft.endingIndex = index + jumpLeftOffset;
            
            if ([self isMoveValid:jumpLeft]) {
                [validJumps addObject:jumpLeft];
            }
            
            Move *jumpRight = [[Move alloc] init];
            jumpRight.player = player;
            jumpRight.isJump = YES;
            jumpRight.capturedIndex = index + slideRightOffset;
            jumpRight.startingIndex = index;
            jumpRight.endingIndex = index + jumpRightOffset;
            
            if ([self isMoveValid:jumpRight]) {
                [validJumps addObject:jumpRight];
            }
            
            Move *slideLeft = [[Move alloc] init];
            slideLeft.player = player;
            slideLeft.startingIndex = index;
            slideLeft.endingIndex = index + slideLeftOffset;
            
            if ([self isMoveValid:slideLeft]) {
                [validSlides addObject:slideLeft];
            }
            
            Move *slideRight = [[Move alloc] init];
            slideRight.player = player;
            slideRight.startingIndex = index;
            slideRight.endingIndex = index + slideRightOffset;
            
            if ([self isMoveValid:slideRight]) {
                [validSlides addObject:slideRight];
            }
        }
        
        index++;
    }
    
    // If jumps are available, those are the only moves allowed
    if (validJumps.count > 0) {
        return validJumps;
    } else {
        return validSlides;
    }
}

- (BOOL)isMoveValid:(Move *)move {
    BOOL isMoveValid = YES;
    
    // Out of bounds moves not allowed. Exit early to avoid index issues.
    if (move.endingIndex < 0 || move.endingIndex > 63) {
        return NO;
    }
    
    if (move.capturedIndex < 0 || move.capturedIndex > 63) {
        return NO;
    }
    
    // Is target location unoccupied?
    if (![self.gameBoardData[move.endingIndex] isEqualToString:EMPTY]) {
        isMoveValid = NO;
    }
    
    if (move.isJump) {
        // Is move in correct row?
        // since we are using a flat array, we must additionally ensure that the ending location is not in another row
        NSInteger startingRow = (move.startingIndex - (move.startingIndex % 8)) / 8;
        NSInteger endingRow = (move.endingIndex - (move.endingIndex % 8)) / 8;
        
        if (labs(endingRow - startingRow) != 2) {
            isMoveValid = NO;
        }
        
        // Is opponent piece in appropriate position?
        if ([self.gameBoardData[move.capturedIndex] isEqualToString:EMPTY] || [self.gameBoardData[move.capturedIndex] isEqualToString:move.player]) {
            isMoveValid = NO;
        }
        
    } else {
        // Is move in correct row?
        // since we are using a flat array, we must additionally ensure that the ending location is not in another row
        NSInteger startingRow = (move.startingIndex - (move.startingIndex % 8)) / 8;
        NSInteger endingRow = (move.endingIndex - (move.endingIndex % 8)) / 8;
        
        if (labs(endingRow - startingRow) != 1) {
            isMoveValid = NO;
        }
    }
    
    return isMoveValid;
}

#pragma mark Touch Handling

- (void)handleCheckerMovement:(UIPanGestureRecognizer *)sender {
    UIView *checker = sender.view;
    _currentCheckerView = checker;
    CGPoint location = [sender locationInView:checker.superview];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        _currentCheckerOriginalLocation = checker.center;
        for (UIView *square in _playableSquares) {
            if (CGRectContainsPoint([square frame], location)) {
                _startingIndex = square.tag;
            }
        }
        
        [checker.superview bringSubviewToFront:checker];
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        self.checkerBoard.userInteractionEnabled = NO;
        NSInteger endingIndex = -1;
        for (UIView *square in _playableSquares) {
            if (CGRectContainsPoint([square frame], location)) {
                endingIndex = square.tag;
            }
        }
        
        Move *attemptedMove = [[Move alloc] init];
        attemptedMove.player = RED;
        attemptedMove.startingIndex = _startingIndex;
        attemptedMove.endingIndex = endingIndex;
        
        // A slide may only be at an index offset of 7 or 9, so we must be trying to jump
        if (labs(_startingIndex - endingIndex) > 9) {
            attemptedMove.isJump = YES;
            // guess at the piece to capture.
            attemptedMove.capturedIndex = _startingIndex + ((endingIndex - _startingIndex) / 2);
        }
        
        BOOL didPerformMove = NO;
        
        for (Move *move in _validMoves) {
            if ([attemptedMove isEqual:move]) {
                [self makeMove:attemptedMove];
                
                didPerformMove = YES;
            }
        }
        
        if (!didPerformMove) {
            checker.center = _currentCheckerOriginalLocation;
            self.checkerBoard.userInteractionEnabled = YES;
        }
        
    } else {
        checker.center = location;
    }
}

#pragma mark UI Updates and Layout

- (void)updateGameboardOnMove:(Move *)move {
    if ([move.player isEqualToString:BLACK]) {
        for (UIView *checker in _blackCheckerViews) {
            if (checker.tag == move.startingIndex) {
                _currentCheckerView = checker;
            }
        }
    } else {
        for (UIView *checker in _redCheckerViews) {
            if (checker.tag == move.startingIndex) {
                _currentCheckerView = checker;
            }
        }
    }
    
    _currentCheckerView.tag = move.endingIndex;
    
    for (UIView *square in _playableSquares) {
        if (square.tag == move.endingIndex) {
            [UIView animateWithDuration:0.15 animations:^{
                _currentCheckerView.center = [self.checkerBoard convertPoint:square.center fromView:square.superview];
            }];
        }
    }
    
    if (move.isJump) {
        UIView *removedChecker;
        
        // Remove the captured piece
        for (UIView *square in _playableSquares) {
            if (square.tag == move.capturedIndex) {
                if ([move.player isEqualToString:RED]) {
                    // Find the right checker
                    for (UIView *checker in _blackCheckerViews) {
                        if (checker.tag == move.capturedIndex) {
                            [checker removeFromSuperview];
                            removedChecker = checker;
                        }
                    }
                    
                    [_blackCheckerViews removeObject:removedChecker];
                } else {
                    // Find the right checker
                    for (UIView *checker in _redCheckerViews) {
                        if (checker.tag == move.capturedIndex) {
                            [checker removeFromSuperview];
                            removedChecker = checker;
                        }
                    }
                    
                    [_redCheckerViews removeObject:removedChecker];
                }
            }
        }
    }
}

- (void)layoutCheckersBoard {
    // Store an array of playable (dark) squares to make hit testing easier
    _playableSquares = [@[] mutableCopy];
    
    for (int column = 0; column < 8; column++) {
        for (int row = 0; row < 8; row++) {
            if ([self isEven:row] != [self isEven:column]) {
                UIView *checkerBoardSquare = [[UIView alloc] init];
                [checkerBoardSquare setTranslatesAutoresizingMaskIntoConstraints:NO];
                checkerBoardSquare.backgroundColor = [UIColor darkGrayColor];
                
                // Tagged with a value that will match the game data index representing this square
                checkerBoardSquare.tag = (8 * column) + row;
                
                [self.checkerBoard addSubview:checkerBoardSquare];
                [_playableSquares addObject:checkerBoardSquare];
                
                // Each square is 1/8 of the width/height of the game board
                NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:checkerBoardSquare attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.checkerBoard attribute:NSLayoutAttributeWidth multiplier:0.125f constant:0.f];
                NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:checkerBoardSquare attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.checkerBoard attribute:NSLayoutAttributeHeight multiplier:0.125f constant:0.f];
                
                // Each square's location is calculated as a proportional offset from the parent view's center coordinates
                NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:checkerBoardSquare attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.checkerBoard attribute:NSLayoutAttributeCenterX multiplier:[self getMultiplierForRowOrColumn:row] constant:0.f];
                NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:checkerBoardSquare attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.checkerBoard attribute:NSLayoutAttributeCenterY multiplier:[self getMultiplierForRowOrColumn:column] constant:0.f];
                
                [self.checkerBoard addConstraint:width];
                [self.checkerBoard addConstraint:height];
                [self.checkerBoard addConstraint:centerX];
                [self.checkerBoard addConstraint:centerY];
            }
        }
    }
    
    [self.checkerBoard layoutIfNeeded];
}

- (void)createCheckers {
    _blackCheckerViews = [@[] mutableCopy];
    _redCheckerViews = [@[] mutableCopy];
    
    NSInteger currentIndex = 0;
    
    for (NSString *square in self.gameBoardData) {
        if (![square isEqualToString:EMPTY]) {
            UIView *currentSquare = [self.checkerBoard viewWithTag:currentIndex];
            
            // Create the checker
            UIView *checker = [[UIView alloc] initWithFrame:CGRectMake(0.f,
                                                                       0.f,
                                                                       currentSquare.bounds.size.width - 2,
                                                                       currentSquare.bounds.size.height - 2)];
            checker.tag = currentIndex;
            [self.checkerBoard addSubview:checker];
            checker.center = [self.checkerBoard convertPoint:currentSquare.center fromView:currentSquare.superview];
            
            // Apply styling
            [checker.layer setCornerRadius:(checker.bounds.size.width / 2)];
            [checker.layer setBorderColor:[UIColor lightGrayColor].CGColor];
            [checker.layer setBorderWidth:1.5f];
            
            // Make sure we have the correct color, and add gesture support to the human player's checkers (red)
            if ([square isEqualToString:RED]) {
                checker.backgroundColor = [UIColor redColor];
                
                UIPanGestureRecognizer *checkerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCheckerMovement:)];
                [checker addGestureRecognizer:checkerPan];
                
                [_redCheckerViews addObject:checker];
                
            } else {
                checker.backgroundColor = [UIColor blackColor];
                [_blackCheckerViews addObject:checker];
            }
        }
        currentIndex++;
    }
}

#pragma mark Helper and Utility Methods

- (CGFloat)getMultiplierForRowOrColumn:(NSInteger)rowOrColumn {
    CGFloat ratio = (((CGFloat)rowOrColumn * 2) + 1) / 8;
    
    // Prevent ratio from being zero - NSLayoutConstraint does not accept multipliers <= 0
    if (ratio < FLT_EPSILON) {
        ratio = 1.f;
    }
    
    return ratio;
}

- (BOOL)isEven:(NSInteger)number {
    return number % 2;
}

@end
