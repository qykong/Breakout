//
//  ViewController.swift
//  Breakout
//
//  Created by 孔去愚 on 15/10/26.
//  Copyright © 2015年 孔去愚. All rights reserved.
//

import UIKit

class BreakoutViewController: UIViewController, UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate
{
// MARK: - gestures
    @IBAction func start(sender: UITapGestureRecognizer) {
        switch sender.state {
        case .Ended:
            if !isStart {
                pushBall(ball!)
                isStart = true
            }
        default:break
        }
    }
    
    @IBAction func movePaddle(sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .Ended:fallthrough
        case .Changed:
            if isStart {
                let x = sender.translationInView(gameView).x
                setPaddlePosition(x)
                sender.setTranslation(CGPointZero, inView: gameView)
            }
        default:break
        }
    }
    
    private func setPaddlePosition(x: CGFloat) {
        let frame = CGRectMake(min(max(0,x+(paddle?.frame.minX)!),gameView.frame.maxX-(paddle?.frame.width)!), (paddle?.frame.minY)!, (paddle?.frame.width)!, (paddle?.frame.height)!)
        paddle?.frame = frame
        collision.removeBoundaryWithIdentifier(Constants.addPaddleBoundary)
        collision.addBoundaryWithIdentifier(Constants.addPaddleBoundary, fromPoint: (paddle?.frame.origin)!, toPoint: CGPoint(x:(paddle?.frame.maxX)!, y:(paddle?.frame.origin.y)!))
    }

// MARK: - setting values
    var isStart = false
    var multipleHitsAtOneSpecialBrick: Int = -1 //deal with the bug that the ball may scroll over the special bricks sometime causing the disappearance immediately. Actually, I haven't yet figure out why this happens.
    var hitsCount = 0
    var defaults = NSUserDefaults.standardUserDefaults()

    var numberOfSpecialBricks = 2
    var numberOfRows = 3
    var speed:CGFloat = 0.4
    
    var ballBounces = 0.75
    let bricksPerRow:CGFloat = 7
    let bricksGap:CGFloat = 5
    let gameViewHeight:CGFloat = 40
    var paddleWidth:CGFloat = 130
    let paddleHeight:CGFloat = 10
    let ballRadius:CGFloat = 7
    var numberOfBricks: Int? {
        return numberOfRows * Int(bricksPerRow)
    }
    
    var indexOfSpecialBricks = [Int]()
    
    var ball: ballView?
    var paddle: UIView?
    var bricks = [UIView]()
    var gameView = UIView()
    
    lazy var animator: UIDynamicAnimator = {
        let temp = UIDynamicAnimator(referenceView: self.gameView)
        temp.delegate = self
        return temp
    }()
    
    lazy var collision = UICollisionBehavior()
    
    lazy var item: UIDynamicItemBehavior = {
        let temp = UIDynamicItemBehavior()
        temp.elasticity = 1
        temp.friction = 0
        temp.resistance = 0
        temp.allowsRotation = false
        return temp
    }()
    
// MARK: - game body
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        numberOfSpecialBricks = defaults.objectForKey(settings.NumberOfSpecialBricks) as? Int ?? 0
        numberOfRows = defaults.objectForKey(settings.NumberOfRows) as? Int ?? 1
        speed = CGFloat(defaults.objectForKey(settings.Speed) as? Float ?? 0.3)
        //get Start
        isStart = false
        startView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.darkGrayColor()
        
        //add gameview
        gameView.frame = CGRectMake(0, gameViewHeight, self.view.frame.width, self.view.frame.height - gameViewHeight)
        self.view.addSubview(gameView)
        animator.addBehavior(collision)
        collision.collisionDelegate = self
        animator.addBehavior(item)
        collision.addBoundaryWithIdentifier(Constants.addSidesBoundaries, fromPoint: CGPoint(x: 0, y: 0), toPoint: CGPoint(x: 0, y: gameView.frame.height))
        collision.addBoundaryWithIdentifier(Constants.addSidesBoundaries, fromPoint: CGPoint(x: 0, y: 0), toPoint: CGPoint(x: gameView.frame.width, y: 0))
        collision.addBoundaryWithIdentifier(Constants.addSidesBoundaries, fromPoint: CGPoint(x: gameView.frame.width, y: 0), toPoint: CGPoint(x: gameView.frame.width, y: gameView.frame.height))
        
    }
    
    private func startView() {
        //default settings
        for brick in bricks {
            brick.removeFromSuperview()
            collision.removeBoundaryWithIdentifier(bricks.indexOf(brick)!)
        }
        bricks.removeAll()
        paddle?.removeFromSuperview()
        collision.removeBoundaryWithIdentifier(Constants.addPaddleBoundary)
        ball?.removeFromSuperview()
        hitsCount = 0
        if ball != nil {
            collision.removeItem(ball!)
        }
        indexOfSpecialBricks.removeAll()
        multipleHitsAtOneSpecialBrick = -1
        
        //add bricks
        IndexOfSpecialBricks()
        let brickWidthPlusBrickGap = (gameView.frame.width-bricksGap) / bricksPerRow
        let brickHeightPlusBrickGap = brickWidthPlusBrickGap / 4 + bricksGap*3 / 4
        for i in 0..<numberOfBricks! {
            let origin = CGPoint(x: CGFloat(i%Int(bricksPerRow))*brickWidthPlusBrickGap, y: CGFloat(i/Int(bricksPerRow))*brickHeightPlusBrickGap)
            addBrick(origin, i: i)
        }
        
        //add paddle
        let wBounce = gameView.frame.width
        let hBounce = gameView.frame.height
        let paddleFrame = CGRectMake(wBounce / 2 - paddleWidth / 2, hBounce - paddleHeight * 14, paddleWidth, paddleHeight)
        paddle = UIView(frame: paddleFrame)
        paddle!.backgroundColor = UIColor.orangeColor()
        gameView.addSubview(paddle!)
        collision.addBoundaryWithIdentifier(Constants.addPaddleBoundary, fromPoint: (paddle?.frame.origin)!, toPoint: CGPoint(x:(paddle?.frame.maxX)!, y:(paddle?.frame.origin.y)!))
        
        //set ball
        let ballFrame = CGRectMake(paddle!.frame.midX-ballRadius, paddle!.frame.minY-ballRadius*2, ballRadius*2, ballRadius*2)
        ball = ballView(frame: ballFrame)
        let path = UIBezierPath(ovalInRect: CGRectMake(0, 0, ballRadius*2, ballRadius*2))
        ball!.backgroundColor = UIColor.clearColor()
        ball!.path = path
        gameView.addSubview(ball!)
        collision.addItem(ball!)
        item.addItem(ball!)
        item.action = {[unowned self] in
            if self.ball?.center.y > self.gameView.frame.maxY {
                let alertLose = UIAlertController(title: nil, message: "YOU LOSE!", preferredStyle: UIAlertControllerStyle.Alert)
                alertLose.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(alertLose , animated: true, completion: nil)
                self.isStart = false
                self.startView()
                
            }
        }
    }
    
    private func addBrick(brickOrigin: CGPoint, i: Int) {
        let brickWidth = (gameView.frame.width - bricksGap) / bricksPerRow - bricksGap
        let brickSize = CGSize(width: brickWidth, height: brickWidth / 4)
        var brickFrame = CGRect(origin: brickOrigin, size: brickSize)
        brickFrame.origin.x += bricksGap
        let brick = UIView(frame: brickFrame)
        if (numberOfSpecialBricks > 0) && (indexOfSpecialBricks[i] == -1) {
            brick.backgroundColor = UIColor.blueColor()
        } else {
            brick.backgroundColor = UIColor.yellowColor()
        }
        bricks.append(brick)
        gameView.addSubview(bricks[i])
        collision.addBoundaryWithIdentifier(i , forPath: UIBezierPath(rect: brick.frame))
    }
    
    private func pushBall(ball: UIView) {
        let push = UIPushBehavior(items: [ball], mode: .Instantaneous)
        push.angle = min(CGFloat(M_PI*3/4),max(CGFloat.randomAngle(),CGFloat(M_PI/4)))
        push.magnitude = speed
        push.action = {[unowned push] in
            self.animator.removeBehavior(push)
        }
        animator.addBehavior(push)
    }
    
    // this function is used to creat a random array represented for the position of special bricks
    private func IndexOfSpecialBricks(){
        if numberOfSpecialBricks > 0 && numberOfSpecialBricks <= numberOfBricks{
            var temp = [Int]()
            var k = 0
            for i in 0..<numberOfBricks! {
                temp.append(i)
            }
            while k < numberOfSpecialBricks {
                let j = Int(arc4random()) % numberOfBricks!
                if temp[j] != -1 {
                    temp[j] = -1
                    k++
                }
            }
            indexOfSpecialBricks = temp
        }
    }
    
// MARK: - deal with collisions
    func collisionBehavior(behavior: UICollisionBehavior, beganContactForItem item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, atPoint p:CGPoint) {
        if let i = identifier as? Int {
            if multipleHitsAtOneSpecialBrick != i {
                if numberOfSpecialBricks>0 && indexOfSpecialBricks[i] == -1 {
                    bricks[i].backgroundColor = UIColor.yellowColor()
                    indexOfSpecialBricks[i] = 0
                    multipleHitsAtOneSpecialBrick = i
                } else {
                    multipleHitsAtOneSpecialBrick = -1
                    UIView.transitionWithView(bricks[i], duration: 0.5, options: UIViewAnimationOptions.BeginFromCurrentState, animations: { () -> Void in
                        self.bricks[i].backgroundColor = UIColor.darkGrayColor()
                        }, completion: nil)
                    UIView.animateWithDuration(1, delay: 0.75, options: .CurveEaseInOut, animations: { () -> Void in
                        self.bricks[i].alpha = 0
                        }, completion: nil)
                    collision.removeBoundaryWithIdentifier(i)
                    if ++hitsCount == numberOfBricks {
                        startView()
                        let alertWin = UIAlertController(title: "YOU WIN!", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                        alertWin.addAction(UIAlertAction(title: "Restart", style: .Cancel, handler: nil))
                        presentViewController(alertWin, animated: true, completion: nil)
                    }
                }
            }
        } else { multipleHitsAtOneSpecialBrick = -1 }
    }

// MARK: - constants
    struct Constants {
        static let addPaddleBoundary = "add paddle boundary"
        static let addSidesBoundaries = "add sides boundaries"
    }
}

private extension CGFloat {
    static func randomAngle() -> CGFloat {
        var x: Double?
        var y: Double?
        repeat{
            x = Double(arc4random())
            y = Double(arc4random())
        } while (x == 0 || y == 0)
        
        return CGFloat(x!/y!)
    }
}

class ballView:UIView {
    var path: UIBezierPath? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        if path != nil {
            UIColor.redColor().set()
            path!.fill()
        }
    }
}

