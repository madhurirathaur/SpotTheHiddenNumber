//
//  ContentView.swift
//  Sample
//
//  Created by MVijay on 30/08/23.
//

import SwiftUI
import AVFoundation
enum Name : String {
    case nameA, nameB
}
 
protocol GameAble {
    var background : Image { get }
}

class Game : GameAble {
    var background: Image {
        Image("\(level)", bundle: nil)
    }
    
    var textColor: Color {
        switch level {
        case 1:
                .orange
        case 2:
                .red
        case 3:
                .red
        case 4:
                .green
        case 5:
                .black
        default:
                .green
        }
    }
    var highlightTextColor: Color {
        switch level {
        case 1:
                .red
        case 2:
                .green
        case 3:
                .green
        case 4:
                .red
        case 5:
                .yellow
        default:
                .green
        }
    }
    var time: Int {
        switch level {
        case 1:
           return 20
        case 2:
            return 20
        case 3:
            return 15
        case 4:
            return 15
        default:
            return 10
        }
    }
    
    var maxScore: Int {
        return numbers.count * level
    }
    
    
    var numbers: [Int] {
        return  [Int](1...10)
    }
    
    var level = 1
    static let shared = Game()
    private init () {}
    
    func nextLevel() {
        level = level + 1
    }
    
    func restart() {
        level = 1
    }
    
    var audioPlayer: AVAudioPlayer?
    func playSound(sound: String) {
        guard let audioData = NSDataAsset(name: sound)?.data else {
            fatalError("Could not find \(sound) in asset catalog.")
        }
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.play()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    func stopPlaying() {
        guard let audioPlayer else { return }
        if audioPlayer.isPlaying  {
            audioPlayer.stop()
        }
    }
    
}

struct ContentView: View {
   
    @State private var nums = Game.shared.numbers
    @State private var score = 0
    @State private var offsets = Array(repeating: CGRect(), count: 10)
    @State private var timeRemaining = Game.shared.time {
        didSet {
            Game.shared.playSound(sound: "tock")
        }
    }
    @State private var showAlert = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var revel = false
    var body: some View {
            VStack {

                GeometryReader { proxy in
                    
                    HStack { Text("Score: \(score)").font(.subheadline).bold()
                        Spacer()
                        Text("Level: \(Game.shared.level)").font(.subheadline).bold()
                        Spacer()
                        Text("Time left: \(timeRemaining)").font(.subheadline).bold()
                    }
                    ZStack {
                        ForEach(0..<nums.count, id:\.self) { index in
                            
                            CirclesView(index: nums[index], offset: CGSize(width: offsets[index].origin.x, height: offsets[index].origin.y), highlight: revel)
                            
                                .onTapGesture { point in
                                    if offsets.contains(where: { $0.contains(point)}) {
                                        
                                        if let idx = offsets.firstIndex(where: { $0.contains(point)}) {
                                            
                                            offsets.remove(at: idx)
                                            nums.remove(at: idx)
                                            
                                            score = score + 1
                                            
                                            if score == Game.shared.maxScore { //All found
                                                Game.shared.stopPlaying()
                                                timer.upstream.connect().cancel()
                                                showAlert.toggle()
                                            }
                                            
                                        }
                                    }
                                }
                        }
                    }
                    .onAppear {
                        logicalFunction(size: proxy.size)
                    }
                    .alert(score < Game.shared.maxScore ? "You lost the match" : "Next Level", isPresented: $showAlert) {
                        if score < Game.shared.maxScore {
                            
                            
                            Button("Exit", role: .cancel) {
                                exit(0)
                            }
                            Button("Restart", role: .none) {
                                revel = false
                                Game.shared.restart()
                                score = 0
                                updateValues(size: proxy.size)
                                showAlert = false
                            }
                        }
                        else {
                            Button("OK", role: .cancel) {
                                Game.shared.nextLevel()
                                updateValues(size: proxy.size)
                                showAlert = false
                            }
                        }
                    }
                }.background(Game.shared.background.resizable().aspectRatio( contentMode: .fill).ignoresSafeArea())
                    .onReceive(timer) { _ in
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                        } else {
                            if !showAlert {
                                revel = true
                                showAlert.toggle()
                                timer.upstream.connect().cancel()
                            }
                        }
                    }

                
            }
    }

    
    private func updateValues(size: CGSize) {
        nums = Game.shared.numbers
        logicalFunction(size: size)
        timeRemaining = Game.shared.time
        instantiateTimer()
    }
    
    private func logicalFunction(size: CGSize)  {
        offsets = Array(repeating: CGRect(), count: nums.count)
        print(nums)
        for index in 0..<nums.count {
            let width: CGFloat = CGFloat.random(in: 0.0...size.width - 100)
            let height: CGFloat = CGFloat.random(in: 0.0...size.height  - 100)
            let a = CGRect(origin: CGPoint(x: width, y: height), size: CGSize(width: 50, height: 50))
            offsets[index] = a
        }
    }
    
    func instantiateTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
}

struct CirclesView: View {
    
    let index: Int
    let offset: CGSize
    let highlight : Bool
    
    var body: some View {
        Text(String(describing: index))
            .frame(width: 50, height: 50, alignment: .center)
            .offset(offset)
            .font(.system(size: 40)).bold()
            .foregroundColor(highlight ?  Game.shared.highlightTextColor : Game.shared.textColor)
            .opacity(0.8)
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
