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
  @State private var isPresented = false
  @State var audioPlayer: AVAudioPlayer!
  @State private var isRotated = false
  
  @State var diceOne = 1
  @State var diceTwo = 1
  @State var diceThree = 1
  @State var diceFour = 1
  @State var diceFive = 1
  
  @State var rollDice1 = true
  @State var rollDice2 = true
  @State var rollDice3 = true
  @State var rollDice4 = true
  @State var rollDice5 = true
  
  @State var rollNumber = 0
  
  func allTrue() {
    self.rollDice1 = true
    self.rollDice2 = true
    self.rollDice3 = true
    self.rollDice4 = true
    self.rollDice5 = true
  }
  func allFalse() {
    self.rollDice1 = false
    self.rollDice2 = false
    self.rollDice3 = false
    self.rollDice4 = false
    self.rollDice5 = false
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
      
      Image("background3")
        .resizable()
        .edgesIgnoringSafeArea(.all)
      VStack {
        
        HStack {
          
          Button {
            isPresented.toggle()
          } label: {
            Image(systemName: "info.circle")
              .foregroundColor(.black)
            
          }
          
          .fullScreenCover(isPresented: $isPresented, content: FullScreenModalView.init)
          
          
          
        }
        .padding(.top)
        Spacer()
        Spacer()
        Text("Roll")
          .font(Font.custom("PaytoneOne-Regular", size: 30))
          .foregroundColor(.black)
          .navigationBarTitle("")
          .navigationBarHidden(true)
        
        
        Image("metal\(rollNumber)")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 190)
        Spacer()
      }
      HStack {
        VStack {
          DiceView(n: diceOne, rollDice: rollDice1, isRotated: isRotated)
          DiceView(n: diceTwo, rollDice: rollDice2, isRotated: isRotated)
          DiceView(n: diceThree, rollDice: rollDice3, isRotated: isRotated)
          DiceView(n: diceFour, rollDice: rollDice4, isRotated: isRotated)
          DiceView(n: diceFive, rollDice: rollDice5, isRotated: isRotated)
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
          Button {self.rollDice1.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDice1 ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDice1 ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDice2.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDice2 ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDice2 ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDice3.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDice3 ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDice3 ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDice4.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDice4 ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDice4 ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          Button {self.rollDice5.toggle()}
        label: {
          RoundedRectangle(cornerRadius: 25)
            .fill(rollDice5 ? Color("dutchGreen") : Color("diceRed"))
            .padding(.all)
            .frame(width: 150, height: 105)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text(rollDice5 ? "Hold?" : "HELD!")
                .font(Font.custom("PaytoneOne-Regular", size: 20))
                .foregroundColor(.black)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            })
        }
          
          
          Spacer()
          Button {
            if rollDice1 {
              self.diceOne = Int.random(in: 1...6)
            }
            if rollDice2 {
              self.diceTwo = Int.random(in: 1...6)
            }
            if rollDice3 {
              self.diceThree = Int.random(in: 1...6)
            }
            if rollDice4 {
              self.diceFour = Int.random(in: 1...6)
            }
            if rollDice5 {
              self.diceFive = Int.random(in: 1...6)
            }
            if rollNumber == 3 {
              AudioServicesPlaySystemSound(1305)
              diceReset()
              allTrue()
              
            } else {
              self.audioPlayer.play()
              isRotated.toggle()
              rollNumber += 1
            }
          }
        label: {
          RoundedRectangle(cornerRadius: 85)
            .fill(LinearGradient(gradient: Gradient(colors: [Color("dutchGreen"), Color("dutchGreenDark")]), startPoint: .leading, endPoint: .trailing))
            .padding(.all)
            .frame(width: 200, height: 100)
            .shadow(color: .black, radius: 10, x: 3, y: 3   )
            .overlay(HStack {
              Text("ROLL")
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
  let rollDice: Bool
  let isRotated: Bool
  var animation: Animation {
    Animation.spring(response: 1.25)
    
  }
  
  var body: some View {
    
    Image(rollDice ? "dice\(n)" : "diceRed\(n)")
      .resizable()
      .scaledToFit()
      .rotationEffect(Angle.degrees(isRotated ? 1080 : 0))
      .animation(rollDice ? animation : nil)
  }
}







struct FullScreenModalView: View {
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()
      VStack {
        Text("Ship Cap'n Crew")
          .font(.title)
          .foregroundColor(.white)
          .bold()
        Spacer()
        
        Text("Roll the dice and once you have a 4 5 and 6, the remaining two dice add up to your point. You may hold and roll dice as you please, but you only get three rolls per turn.")
          .foregroundColor(.white)
          .padding(.horizontal)
        Text("On roll 3, when you press Roll, the game will automatically reset")
          .foregroundColor(.white)
          .padding(.top)
          .padding(.horizontal)
        
        Spacer()
        
        Button {
          dismiss()
        }
      label: {
        Text("Back To The Game")
          .foregroundColor(.white)
      }
        
      }
    }
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .previewInterfaceOrientation(.portraitUpsideDown)
  }
}
