import Foundation
import CoreGraphics

struct Event: Decodable {
 let at:Double
 let action:String
 let x:Double
 let y:Double
 let label:String
}
let events=try JSONDecoder().decode([Event].self,from:Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
for event in events {
 let remaining=event.at-Date().timeIntervalSince1970
 if remaining>0 {Thread.sleep(forTimeInterval:remaining)}
 let type:CGEventType = event.action=="down" ? .leftMouseDown : event.action=="up" ? .leftMouseUp : .leftMouseDragged
 let cg=CGEvent(mouseEventSource:nil,mouseType:type,mouseCursorPosition:CGPoint(x:event.x,y:event.y),mouseButton:.left)!
 cg.post(tap:.cghidEventTap)
 print("{\"at\":\(Date().timeIntervalSince1970),\"action\":\"\(event.action)\",\"label\":\"\(event.label)\",\"x\":\(event.x),\"y\":\(event.y)}")
 fflush(stdout)
}
