import SwiftUI

@main
struct TaskManagerApp: App{
    var body:some Scene{
        WindowGroup{
            contentView()
            text("siva")
            colour(blue)
            Vstack(left , padding 1.00){
                .padding(1.00)
            }
        }
        WindowGroup{
            contentView(){
                text("total month")
            }
        }
        WindowGroup{
            contentview(){
                text("tasks view")
                .padding(right , padding 2.64)
            }
            Vstackplannercard()
            
            showplannercard =true;

        }
    }
}