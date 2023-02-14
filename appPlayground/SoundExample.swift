//
//  SwiftUIView.swift
//  appPlayground
//
//  Created by Dan Payne on 2/13/23.
//
//import AVFoundation
//import AVKit
//import SwiftUI
//
//struct SwiftUIView: View {
//  @State var audioPlayer: AVAudioPlayer!
//    var body: some View {
//      ZStack {
//                 VStack {
//                         Text("Play").font(.system(size: 45)).font(.largeTitle)
//                     HStack {
//                         Spacer()
//                         Button(action: {
//                             
//                         }) {
//                             Image(systemName: "play.circle.fill").resizable()
//                                 .frame(width: 50, height: 50)
//                                 .aspectRatio(contentMode: .fit)
//                         }
//                         Spacer()
//                         Button(action: {
//                             self.audioPlayer.pause()
//                         }) {
//                             Image(systemName: "pause.circle.fill").resizable()
//                                 .frame(width: 50, height: 50)
//                                 .aspectRatio(contentMode: .fit)
//                         }
//                         Spacer()
//                     }
//                 }
//             }
//             .onAppear {
//                 let sound = Bundle.main.path(forResource: "rollDice", ofType: "mp3")
//                 self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
//             }
//    }
//}
//
//struct SwiftUIView_Previews: PreviewProvider {
//    static var previews: some View {
//        SwiftUIView()
//    }
//}
