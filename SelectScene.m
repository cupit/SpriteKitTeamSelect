#import "SelectScene.h"

typedef enum {
    Left = 0,
    Center,
    Right
} Zone;

@interface SelectScene ()

@property (nonatomic, strong) NSMutableArray* players;
@property (nonatomic, strong) SKSpriteNode* leftPlayer;
@property (nonatomic, strong) SKSpriteNode* centerPlayer;
@property (nonatomic, strong) SKSpriteNode* rightPlayer;

@property (nonatomic, assign) CGFloat leftGuide;
@property (nonatomic, assign) CGFloat rightGuide;
@property (nonatomic, assign) CGFloat gap;

@end

@implementation SelectScene


- (id)initWithSize: (CGSize)size
{
    if (self = [super initWithSize: size])
    {
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        
        
        self.players = [NSMutableArray new];
        
        [self createPlayers];
        self.centerPlayer = (SKSpriteNode*)[self.players objectAtIndex: self.players.count / 2];
        [self setLeftAndRightPlayers];
    }
    return self;
}


- (void)didMoveToView:(SKView *)view
{
    [self placePlayersOnPositions];
    [self calculateZIndexesForPlayers];
}


- (CGFloat)leftGuide
{
    return round(self.size.width / 6.0);
}


- (CGFloat)rightGuide
{
    return self.size.width - self.leftGuide;
}


- (CGFloat)gap
{
    return (self.size.width / 2 - self.leftGuide) / 2;
}


- (void)createPlayers
{
    for (int i = 0; i < 9; ++ i)
    {
        SKSpriteNode* player = [SKSpriteNode spriteNodeWithColor: [SKColor redColor] size: CGSizeMake(100.0, 200.0)];
        [self.players addObject: player];
    }
}


- (void)setLeftAndRightPlayers
{
    NSInteger playerCenterIndex = self.players.count / 2;
    
    for (int i = 0; i < self.players.count; ++i)
    {
        if (self.centerPlayer == self.players[i])
        {
            playerCenterIndex = i;
        }
    }
    
    if (playerCenterIndex > 0 && playerCenterIndex < self.players.count)
    {
        self.leftPlayer = self.players[playerCenterIndex - 1];
    }
    else
    {
        self.leftPlayer = nil;
    }
    
    if (playerCenterIndex > -1 && playerCenterIndex < self.players.count - 1)
    {
        self.rightPlayer = self.players[playerCenterIndex + 1];
    }
    else
    {
        self.rightPlayer = nil;
    }
}


- (void)placePlayersOnPositions
{
    for (int i = 0; i < self.players.count / 2; ++ i)
    {
        SKSpriteNode* player = self.players[i];
        player.position = CGPointMake(self.leftGuide, self.size.height / 2.0);
    }

    SKSpriteNode* centerPlayer =  self.players[self.players.count / 2];
    centerPlayer.position = CGPointMake(self.size.width / 2.0, self.size.height / 2.0);
    
    for (int i = (self.players.count + 1) / 2; i < self.players.count; ++ i)
    {
        SKSpriteNode* player = self.players[i];
        player.position = CGPointMake(self.rightGuide, self.size.height / 2.0);
    }
    
    for (SKSpriteNode* player in self.players)
    {
        player.xScale = [self calculateScaleForX: player.position.x];
        player.yScale = [self calculateScaleForX: player.position.x];
        [self addChild: player];
    }
    
}



- (CGFloat)calculateScaleForX: (CGFloat)xPosition
{
    CGFloat minScale = 0.5;
    
    if (xPosition <= self.leftGuide || xPosition >= self.rightGuide)
    {
        return minScale;
    }
    
    if (xPosition < self.size.width * 0.5)
    {
        CGFloat a = 1.0 / (self.size.width - 2.0 * self.leftGuide);
        CGFloat b = 0.5 - a * self.leftGuide;
        
        return (a * xPosition + b);
    }
    
    CGFloat a = 1.0 / (self.size.width - 2.0 * self.rightGuide);
    CGFloat b = 0.5 - a * self.rightGuide;
    
    return (a * xPosition + b);
}


- (void)calculateZIndexesForPlayers
{
    NSInteger playerCenterIndex = self.players.count / 2;
    
    for (int i = 0; i < self.players.count; ++ i)
    {
        if (self.centerPlayer == self.players[i])
        {
            playerCenterIndex = i;
        }
    }
    
    for (int i = 0; i < playerCenterIndex; ++ i)
    {
        SKSpriteNode* player = self.players[i];
        player.zPosition = i;
    }
    
    for (int i = playerCenterIndex + 1; i < self.players.count; ++ i)
    {
        SKSpriteNode* player = self.players[i];
        player.zPosition = self.centerPlayer.zPosition * 2 - i;
    }
}


- (void)movePlayer: (SKSpriteNode*)player toX: (CGFloat)xPosition duration: (CGFloat)duration
{
    SKAction* moveAction = [SKAction moveToX: xPosition duration: duration];
    SKAction* scaleAction = [SKAction scaleTo: [self calculateScaleForX: xPosition] duration: duration];
    
    [player runAction: [SKAction group:@[moveAction, scaleAction]]];
}


- (void)movePlayer: (SKSpriteNode*)player byX: (CGFloat)xPosition
{
    CGFloat duration = 0.01;
    
    if (CGRectGetMidX(player.frame) <= self.rightGuide && CGRectGetMidX(player.frame) >= self.leftGuide)
    {
        [player runAction: [SKAction moveByX: xPosition y: 0.0 duration: duration] completion:^{
            player.xScale = [self calculateScaleForX: CGRectGetMidX(player.frame)];
            player.yScale = [self calculateScaleForX: CGRectGetMidX(player.frame)];
        }];
        
        if (CGRectGetMidX(player.frame) <= self.leftGuide)
        {
            player.position = CGPointMake(self.leftGuide, player.position.y);
        }
        else if (CGRectGetMidX(player.frame) > self.rightGuide)
        {
            player.position = CGPointMake(self.rightGuide, player.position.y);
        }
    }
}


- (Zone)zoneOfCenterPlayer
{
    CGFloat gap = self.size.width * 0.5 - self.leftGuide;
    
    if (CGRectGetMidX(self.centerPlayer.frame) < self.leftGuide + gap * 0.5)
    {
        return Left;
    }
    else if (CGRectGetMidX(self.centerPlayer.frame) > self.rightGuide - gap * 0.5)
    {
        return Right;
    }
    else
    {
        return Center;
    }
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    SKNode* node = [self nodeAtPoint: [touch locationInNode: self]];
    
    if (node == self.centerPlayer)
    {
        SKAction* fadeOut = [SKAction fadeAlphaTo: 0.5 duration: 0.15];
        SKAction* fadeIn = [SKAction fadeAlphaTo: 1.0 duration: 0.15];
        
        [self.centerPlayer runAction: fadeOut completion:^{
            [self.centerPlayer runAction: fadeIn];
        }];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
    CGPoint newPosition = [touch locationInNode: self];
    CGPoint oldPosition = [touch previousLocationInNode: self];
    
    CGFloat xTranslation = newPosition.x - oldPosition.x;
    
    CGFloat actualTranslation;
    if (CGRectGetMidX(self.centerPlayer.frame) > self.size.width * 0.5)
    {
        if (self.leftPlayer)
        {
            actualTranslation = CGRectGetMidX(self.leftPlayer.frame) + xTranslation > self.leftGuide
            ? xTranslation
            : self.leftGuide - CGRectGetMidX(self.leftPlayer.frame);
            [self movePlayer: self.leftPlayer byX: actualTranslation];
        }
    }
    else
    {
        if (self.rightPlayer)
        {
            actualTranslation = CGRectGetMidX(self.rightPlayer.frame) + xTranslation < self.rightGuide
            ? xTranslation
            : self.rightGuide - CGRectGetMidX(self.rightPlayer.frame);
            [self movePlayer: self.rightPlayer byX: actualTranslation];
        }
    }
    
    [self movePlayer: self.centerPlayer byX: xTranslation];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGFloat duration = 0.25;
    
    switch ([self zoneOfCenterPlayer])
    {
        case Left:
            if (self.rightPlayer)
            {
                [self movePlayer: self.centerPlayer toX: self.leftGuide duration: duration];
                
                if (self.leftPlayer)
                {
                    [self movePlayer: self.leftPlayer toX: self.leftGuide duration: duration];
                }
                
                if (self.rightPlayer)
                {
                    [self movePlayer: self.rightPlayer toX: self.size.width * 0.5 duration: duration];
                }
                
                self.centerPlayer = self.rightPlayer;
            }
            else
            {
                [self movePlayer: self.centerPlayer toX: self.size.width * 0.5 duration: duration];
            }
            break;
            
        case Right:
            if (self.leftPlayer)
            {
                [self movePlayer: self.centerPlayer toX: self.rightGuide duration: duration];
                
                if (self.rightPlayer)
                {
                    [self movePlayer: self.rightPlayer toX: self.rightGuide duration: duration];
                }
                
                if (self.leftPlayer)
                {
                    [self movePlayer: self.leftPlayer toX: self.size.width * 0.5 duration: duration];
                }
                
                self.centerPlayer = self.leftPlayer;
            }
            else
            {
                [self movePlayer: self.centerPlayer toX: self.size.width * 0.5 duration: duration];
            }
            break;
            
        case Center:
            [self movePlayer: self.centerPlayer toX: self.size.width * 0.5 duration: duration];
            
            if (self.leftPlayer)
            {
                [self movePlayer: self.leftPlayer toX: self.leftGuide duration: duration];
            }
            
            if (self.rightPlayer)
            {
                [self movePlayer: self.rightPlayer toX: self.rightGuide duration: duration];
            }
            
            break;
            
        default:
            break;
    }
    
    [self setLeftAndRightPlayers];
    [self calculateZIndexesForPlayers];
}

@end
