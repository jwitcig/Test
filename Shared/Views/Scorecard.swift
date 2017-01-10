//
//  ScoreCard.swift
//  MrPutt
//
//  Created by Developer on 1/9/17.
//  Copyright © 2017 CodeWithKenny. All rights reserved.
//

import UIKit

import Cartography

class Scorecard: UIView {

    init(hole: Int, names: (String, String), player1Strokes: [Int], player2Strokes: [Int], pars: [Int]) {
        
        super.init(frame: .zero)
        
        let image = ScoreCardStyleKit.imageOfCard(
                  holeNumber: hole.string!,
                  name1: names.0, name2: names.1,
                
                  player1Hole1: player1Strokes[0].string!,
                  player1Hole2: player1Strokes[1].string!,
                  player1Hole3: player1Strokes[2].string!,
                  player1Hole4: player1Strokes[3].string!,
                  player1Hole5: player1Strokes[4].string!,
                  player1Hole6: player1Strokes[5].string!,
                  player1Hole7: player1Strokes[6].string!,
                  player1Hole8: player1Strokes[7].string!,
                  player1Hole9: player1Strokes[8].string!,
                  
                  player2Hole1: player2Strokes[0].string!,
                  player2Hole2: player2Strokes[1].string!,
                  player2Hole3: player2Strokes[2].string!,
                  player2Hole4: player2Strokes[3].string!,
                  player2Hole5: player2Strokes[4].string!,
                  player2Hole6: player2Strokes[5].string!,
                  player2Hole7: player2Strokes[6].string!,
                  player2Hole8: player2Strokes[7].string!,
                  player2Hole9: player2Strokes[8].string!,
                  
                  parHole1: pars[0].string!,
                  parHole2: pars[1].string!,
                  parHole3: pars[2].string!,
                  parHole4: pars[3].string!,
                  parHole5: pars[4].string!,
                  parHole6: pars[5].string!,
                  parHole7: pars[6].string!,
                  parHole8: pars[7].string!,
                  parHole9: pars[8].string!,
//                  parTotal: pars.reduce(0, +).string!,
                  player1Total: player1Strokes.reduce(0, +).string!,
                  player2Total: player2Strokes.reduce(0, +).string!)
        
        let imageView = UIImageView(image: image)
        addSubview(imageView)
        constrain(imageView, self) {
            $0.center == $1.center
            $0.size == $1.size
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
