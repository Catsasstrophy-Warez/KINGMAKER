import Foundation
import DHCore
import DHVehicle

public struct PlayerInputState: Codable, Sendable, Equatable {
    public var moveX: Double = 0; public var moveY: Double = 0
    public var throttle: Double = 0; public var brake: Double = 0; public var steer: Double = 0
    public var interact = false; public var tacticalSlowdown = false
    public init() {}
}

public struct PlayerAvatarState: Codable, Sendable, Equatable {
    public var position = DHVector3(); public var headingRadians = 0.0; public var walkSpeedMPS = 3.6
    public init() {}
    public mutating func step(input: PlayerInputState, dt: Double) {
        let magnitude = min(1, hypot(input.moveX, input.moveY)); guard magnitude > 0.001 else { return }
        let nx = input.moveX / max(magnitude, 0.001), nz = input.moveY / max(magnitude, 0.001)
        position.x += nx * walkSpeedMPS * magnitude * dt; position.z += nz * walkSpeedMPS * magnitude * dt
        headingRadians = atan2(nx, nz)
    }
}

public struct KingmakerDriveController: Codable, Sendable, Equatable {
    public var speedMPS = 0.0; public var headingRadians = 0.0; public var position = DHVector3(); public var wheelbaseM = 2.85
    public init() {}
    public mutating func step(input: PlayerInputState, dt: Double, running: Bool) {
        guard running else { speedMPS *= max(0, 1 - 2.5 * dt); return }
        let acceleration = max(0, min(1,input.throttle))*7.0 - max(0,min(1,input.brake))*12.0 - 0.018*speedMPS*speedMPS
        speedMPS = max(0, min(72, speedMPS + acceleration*dt))
        let steerAngle = max(-1,min(1,input.steer))*0.52
        headingRadians += (speedMPS / wheelbaseM) * tan(steerAngle) * dt
        position.x += sin(headingRadians)*speedMPS*dt; position.z += cos(headingRadians)*speedMPS*dt
    }
    public var speedKPH: Double { speedMPS * 3.6 }
}

public struct InteractionCandidate: Codable, Sendable, Equatable { public var id:String; public var prompt:String; public var distanceM:Double; public init(id:String,prompt:String,distanceM:Double){self.id=id;self.prompt=prompt;self.distanceM=distanceM} }
public struct InteractionResolver: Sendable {
    public init() {}
    public func best(_ candidates:[InteractionCandidate], maximumDistance:Double=3.0)->InteractionCandidate? { candidates.filter{$0.distanceM <= maximumDistance}.min{$0.distanceM < $1.distanceM} }
}

public struct EngineAudioState: Codable, Sendable, Equatable {
    public var gain=0.0; public var pitch=0.8; public var starterGain=0.0; public var exhaustLoad=0.0
    public init() {}
    public mutating func update(rpm:Double, throttle:Double, cranking:Bool, running:Bool) { starterGain = cranking ? 1:0; gain = running ? min(1,0.25+rpm/7000):0; pitch = 0.75 + min(1.5,rpm/4500); exhaustLoad=max(0,min(1,throttle)) }
}
public struct VehicleFXState: Codable, Sendable, Equatable { public var dust=0.0; public var skid=0.0; public var heatHaze=0.0; public init(){}; public mutating func update(speedKPH:Double,slip:Double,roadDust:Double,coolantC:Double){dust=min(1,speedKPH/55*roadDust);skid=min(1,abs(slip)*2);heatHaze=max(0,min(1,(coolantC-85)/35))} }

public struct InventorySlot: Codable, Sendable, Equatable, Identifiable { public var id:String; public var name:String; public var quantity:Int; public var massKG:Double; public var value:Int; public init(id:String,name:String,quantity:Int=1,massKG:Double,value:Int){self.id=id;self.name=name;self.quantity=quantity;self.massKG=massKG;self.value=value} }
public struct TradeState: Codable, Sendable, Equatable { public var playerCaps:Int=40; public var player:[InventorySlot]=[]; public var merchant:[InventorySlot]=[]; public init(){}; public mutating func buy(id:String){guard let i=merchant.firstIndex(where:{$0.id==id}), playerCaps>=merchant[i].value else{return}; let item=merchant.remove(at:i); playerCaps-=item.value; player.append(item)} }
public extension TradeState {
    mutating func sell(id: String) {
        guard let index = player.firstIndex(where: { $0.id == id }) else { return }
        let item = player.remove(at: index)
        playerCaps += item.value
    }
}

public struct PauseSettingsState: Codable, Sendable, Equatable { public var paused=false; public var masterVolume=0.85; public var musicVolume=0.65; public var radioVolume=0.9; public var cameraSensitivity=1.0; public var haptics=true; public init(){} }
public struct SaveSlotDescriptor: Codable, Sendable, Equatable, Identifiable { public var id:String; public var title:String; public var timestamp:Date; public var region:String; public var distanceKM:Double; public init(id:String,title:String,timestamp:Date=Date(),region:String,distanceKM:Double){self.id=id;self.title=title;self.timestamp=timestamp;self.region=region;self.distanceKM=distanceKM} }
