//
//  ContentView.swift
//  appPlayground
//
//  Created by Dan Payne on 1/5/22.
//
import AVFoundation
import AVKit
import SwiftUI

struct ContentView: View {
  
  @State var audioPlayer: AVAudioPlayer!
  
  
  @State var diceOne = 1
  @State var diceTwo = 1
  @State var diceThree = 1
  @State var diceFour = 1
  @State var diceFive = 1
  
  @State var rollDiceOne = true
  @State var rollDiceTwo = true
  @State var rollDiceThree = true
  @State var rollDiceFour = true
  @State var rollDiceFive = true
  
  @State var rollNumber = 0
  
  func allTrue() {
    self.rollDiceOne = true
    self.rollDiceTwo = true
    self.rollDiceThree = true
    self.rollDiceFour = true
    self.rollDiceFive = true
  }
  func allFalse() {
    self.rollDiceOne = false
    self.rollDiceTwo = false
    self.rollDiceThree = false
    self.rollDiceFour = false
    self.rollDiceFive = false
  }
  func diceReset() {
    diceOne = 1
    diceTwo = 1
    diceThree = 1
    diceFour = 1
    diceFive = 1
    rollNumber -= 3
    
  }
  
  
  
  var body: some View {
    
    ZStack {
      
      Image("background2")
        .resizable()
        .edgesIgnoringSafeArea(.all)
      VStack {
        
        Spacer()
        Text("Roll:")
          .font(Font.custom("PaytoneOne-Regular", size: 30))
          .foregroundColor(.black)
          .navigationBarTitle("")
          .navigationBarHidden(true)
        
        
        Image("metal\(rollNumber)")
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
      HStack {
        VStack {
          DiceView(n: diceOne)
          DiceView(n: diceTwo)
          DiceView(n: diceThree)
          DiceView(n: diceFour)
          DiceView(n: diceFive)
          Spacer()
          VStack {
            Button { allFalse()
            }
          label: {
            RoundedRectangle(cornerRadius: 25)
              .fill(LinearGradient(gradient: Gradient(colors: [Color("diceRedLight"), Color("diceRed")]), startPoint: .leading, endPoint: .trailing))
              .padding(.all)
              .frame(width: 140, height: 80)
              .shadow(color: .black, radius: 10, x: 3, y: 3   )
              .overlay(HStack {
                Text("Hold All")
                  .font(Font.custom("PaytoneOne-Regular", size: 20))
                  .foregroundColor(.black)
                  .navigationBarTitle("")
                  .navigationBarHidden(true)
              })
          }
            Button {allTrue()
            }
          label: {
            RoundedRectangle(cornerRadius: 25)
              .fill(LinearGradient(gradient: Gradient(colors: [Color("dutchGreen"), Color("dutchGreenDark")]), startPoint: .leading, endPoint: .trailing))
              .padding(.all)
              .frame(width: 130, height: 80)
              .shadow(color: .black, radius: 10, x: 3, y: 3   )
              .overlay(HStack {
                
                Text("Roll All")
                
                  .font(Font.custom("PaytoneOne-Regular", size: 20))
                  .foregroundColor(.black)
                  .navigationBarTitle("")
                  .navigationBarHidden(true)
              })
          }
          }
          
        }
        .padding()
        Spacer()
        VStack {
          Button {self.rollDiceOne.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDiceOne ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDiceOne ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDiceTwo.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDiceTwo ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDiceTwo ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDiceThree.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDiceThree ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDiceThree ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDiceFour.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDiceFour ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDiceFour ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDiceFive.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDiceFive ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDiceFive ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Spacer()
          Button {
            if rollDiceOne {
              self.diceOne = Int.random(in: 1...6)
            }
            if rollDiceTwo {
              self.diceTwo = Int.random(in: 1...6)
            }
            if rollDiceThree {
              self.diceThree = Int.random(in: 1...6)
            }
            if rollDiceFour {
              self.diceFour = Int.random(in: 1...6)
            }
            if rollDiceFive {
              self.diceFive = Int.random(in: 1...6)
            }
            if rollNumber == 3 {
              AudioServicesPlaySystemSound(1305)
              diceReset()
              allTrue()
              
            } else {
              self.audioPlayer.play()
              rollNumber += 1
            }
            
            
            
          }
        label: {
          RoundedRectangle(cornerRadius: 85)
            .fill(LinearGradient(gradient: Gradient(colors: [Color("dutchGreen"), Color("dutchGreenDark")]), startPoint: .leading, endPoint: .trailing))
            .padding(.all)
            .frame(width: 130, height: 130)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text("ROLL!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
        }
      }
    }
    .onAppear {
      let sound = Bundle.main.path(forResource: "rollDice", ofType: "mp3")
      self.audioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound!))
      
    }
  }
}
struct DiceView: View {
  let n: Int
  var body: some View {
    Image("dice\(n)")
      .resizable()
      .scaledToFit()
  }
}






struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .previewInterfaceOrientation(.portraitUpsideDown)
  }
}






