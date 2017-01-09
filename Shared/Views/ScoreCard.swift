//
//  ScoreCard.swift
//  MrPutt
//
//  Created by Developer on 1/9/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

class ScoreCard: UIView {

    override func draw(_ rect: CGRect) {
        layer.contentsScale = UIScreen.main.scale
    
        ScoreCardStyleKit.drawCard(frame: rect, resizing: .aspectFit,
                                   name1: "Jonah", name2: "Kenny",
                                   player1Hole1: "1",
                                   player1Hole2: "1",
                                   player1Hole3: "1",
                                   player1Hole4: "1",
                                   player1Hole5: "1",
                                   player1Hole6: "1",
                                   player1Hole8: "1",
                                   player1Hole9: "1",
                                   player2Hole1: "1",
                                   player2Hole2: "1",
                                   player2Hole3: "1",
                                   player2Hole4: "1",
                                   player2Hole5: "1",
                                   player2Hole6: "1",
                                   player2Hole7: "1",
                                   player2Hole8: "1",
                                   player2Hole9: "1",
                                   parHole1: "1",
                                   parHole2: "1",
                                   parHole3: "1",
                                   parHole4: "1",
                                   parHole5: "1",
                                   parHole6: "1",
                                   parHole7: "1",
                                   parHole8: "1",
                                   parHole9: "1",
                                   parTotal: "9",
                                   player1Total: "9",
                                   player2Total: "9")
        
    }
    
}
