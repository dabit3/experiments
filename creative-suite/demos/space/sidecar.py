"""A real native AppKit source viewer for the running GUI test."""
import json
import sys
from pathlib import Path
import AppKit as A
import objc
from Foundation import NSObject, NSTimer

STATE = Path(sys.argv[1])


def color(hex):
    return A.NSColor.colorWithCalibratedRed_green_blue_alpha_(
        int(hex[0:2],16)/255,int(hex[2:4],16)/255,int(hex[4:6],16)/255,1)


class Panel(A.NSView):
    def isFlipped(self):
        return True

    @objc.python_method
    def text(self, string, x, y, size=17, ink="E8EEE9", mono=False):
        font = (A.NSFont.monospacedSystemFontOfSize_weight_(size, A.NSFontWeightRegular)
                if mono else A.NSFont.systemFontOfSize_weight_(size,A.NSFontWeightMedium))
        A.NSString.stringWithString_(str(string)).drawAtPoint_withAttributes_(
            (x,y),{A.NSFontAttributeName:font,A.NSForegroundColorAttributeName:color(ink)})

    def drawRect_(self, rect):
        color("101A20").setFill()
        A.NSRectFill(self.bounds())
        try:
            s=json.loads(STATE.read_text())
        except (OSError,ValueError):
            s={"chapter":"Ready for native UI test", "status":"READY"}
        self.text("SPACE  /  NATIVE UI TEST",32,30,14,"83BDAF",True)
        self.text("ORBIT",30,63,56)
        self.text("A study in copper & porcelain",32,132,21,"B5C7C5")
        color("2A4047").setFill()
        A.NSRectFill(((32,183),(668,1)))
        self.text(s.get("chapter",""),32,212,25)
        self.text(s.get("subtitle","Actual app • actual actions • actual source"),32,255,16,"9FB4B7")
        self.text("EXECUTING  ·  "+s.get("file","scenario.py"),32,310,13,"83BDAF",True)
        lines=s.get("lines",[])
        active=s.get("line",0)
        for i, item in enumerate(lines):
            number, line=item
            y=350+i*25
            if number==active:
                color("213E46").setFill()
                A.NSRectFill(((20,y-3),(695,25)))
                self.text("›",23,y,17,"BAE9CA",True)
            self.text(f"{number:03}",42,y,15,"647F89",True)
            ink="BAE9CA" if number==active else "D3E0E2"
            if line.lstrip().startswith("#"):
                ink="83A2AA"
            self.text(line,88,y,15,ink,True)
        self.text("LIVE ASSERTIONS",32,858,13,"83BDAF",True)
        results=s.get("results",[])
        for i,r in enumerate(results[-9:]):
            ink="FF9D85" if r["status"]=="FAIL" else "BAE9CA"
            self.text(r["status"],32,895+i*32,14,ink,True)
            self.text(r["text"][:61],94,894+i*32,16)
        passed=sum(r["status"]=="PASS" for r in results)
        failed=sum(r["status"]=="FAIL" for r in results)
        color("2A4047").setFill()
        A.NSRectFill(((32,1202),(668,1)))
        self.text(f'{s.get("status","READY")}   /   {passed} checks   /   {failed} failures',
                  32,1224,17,"BAE9CA",True)
        self.text("Quartz pointer + keyboard · native Accessibility",32,1265,14,"819BA3")
        self.text("No document injection. Visuals reviewed separately.",32,1289,14,"819BA3")


class Refresh(NSObject):
    def tick_(self, timer):
        panel.setNeedsDisplay_(True)


app=A.NSApplication.sharedApplication()
app.setActivationPolicy_(A.NSApplicationActivationPolicyAccessory)
window=A.NSWindow.alloc().initWithContentRect_styleMask_backing_defer_(
    ((1665,0),(735,1320)),A.NSWindowStyleMaskBorderless,A.NSBackingStoreBuffered,False)
window.setLevel_(A.NSFloatingWindowLevel)
window.setTitle_("Space • Executing test source")
panel=Panel.alloc().initWithFrame_(((0,0),(735,1320)))
window.setContentView_(panel)
window.orderFrontRegardless()
refresh=Refresh.new()
timer=NSTimer.scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(
    .08,refresh,"tick:",None,True)
app.run()
