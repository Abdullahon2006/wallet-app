import SwiftUI
import SceneKit

/// A 3D card view using SceneKit — a textured plane the user can rotate with drag gestures.
/// Front and back images are mapped to opposing sides of the plane.
@MainActor
struct Card3DView: UIViewRepresentable {
    let frontImage: UIImage?
    let backImage: UIImage?
    let cardColor: Color

    @Binding var isShowingBack: Bool

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.backgroundColor = .clear
        sceneView.autoenablesDefaultLighting = false
        sceneView.antialiasingMode = .multisampling4X

        let scene = SCNScene()
        sceneView.scene = scene

        // Card plane (credit card aspect ratio ≈ 1.586:1)
        let cardWidth: CGFloat = 3.4
        let cardHeight: CGFloat = cardWidth / 1.586
        let cardPlane = SCNPlane(width: cardWidth, height: cardHeight)
        cardPlane.cornerRadius = 0.15

        // Front material
        let frontMaterial = SCNMaterial()
        if let frontImage = frontImage {
            frontMaterial.diffuse.contents = frontImage
        } else {
            frontMaterial.diffuse.contents = UIColor(cardColor)
        }
        frontMaterial.lightingModel = .physicallyBased
        frontMaterial.roughness.contents = 0.4
        frontMaterial.metalness.contents = 0.1

        // Back material
        let backMaterial = SCNMaterial()
        if let backImage = backImage {
            backMaterial.diffuse.contents = backImage
        } else {
            backMaterial.diffuse.contents = UIColor(cardColor).withAlphaComponent(0.8)
        }
        backMaterial.lightingModel = .physicallyBased
        backMaterial.roughness.contents = 0.5
        backMaterial.metalness.contents = 0.05

        cardPlane.materials = [frontMaterial, backMaterial]

        let cardNode = SCNNode(geometry: cardPlane)
        cardNode.name = "card"
        scene.rootNode.addChildNode(cardNode)

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 45
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.4, alpha: 1)
        scene.rootNode.addChildNode(ambientLight)

        // Directional light (top-right)
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor(white: 0.8, alpha: 1)
        directionalLight.light?.castsShadow = true
        directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(directionalLight)

        // Subtle fill light (bottom-left)
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.color = UIColor(white: 0.3, alpha: 1)
        fillLight.eulerAngles = SCNVector3(Float.pi / 6, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)

        // Pan gesture for rotation
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)

        context.coordinator.sceneView = sceneView
        context.coordinator.cardNode = cardNode

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update the flip state if toggled externally
        context.coordinator.updateFlipState(showBack: isShowingBack)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isShowingBack: $isShowingBack)
    }

    @MainActor
    final class Coordinator: NSObject {
        weak var sceneView: SCNView?
        weak var cardNode: SCNNode?
        @Binding var isShowingBack: Bool

        private var currentAngleY: Float = 0
        private var lastPanAngleY: Float = 0

        init(isShowingBack: Binding<Bool>) {
            _isShowingBack = isShowingBack
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let cardNode = cardNode, let view = sceneView else { return }

            let translation = gesture.translation(in: view)

            switch gesture.state {
            case .began:
                lastPanAngleY = currentAngleY

            case .changed:
                let rotationY = lastPanAngleY + Float(translation.x) * 0.01
                let rotationX = Float(translation.y) * 0.005 // Subtle vertical tilt
                currentAngleY = rotationY

                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0
                cardNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
                SCNTransaction.commit()

                // Determine if showing back based on rotation
                let normalizedAngle = normalizeAngle(rotationY)
                let showBack = normalizedAngle > Float.pi / 2 && normalizedAngle < 3 * Float.pi / 2
                if showBack != isShowingBack {
                    self.isShowingBack = showBack
                }

            case .ended, .cancelled:
                // Snap to nearest face
                let normalizedAngle = normalizeAngle(currentAngleY)
                let targetAngle: Float
                if normalizedAngle > Float.pi / 2 && normalizedAngle < 3 * Float.pi / 2 {
                    targetAngle = Float.pi // Show back
                } else {
                    targetAngle = 0 // Show front
                }

                // Compute shortest rotation to target
                let diff = targetAngle - currentAngleY
                let snappedAngle = currentAngleY + diff

                currentAngleY = snappedAngle

                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.3
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                cardNode.eulerAngles = SCNVector3(0, snappedAngle, 0)
                SCNTransaction.commit()

                self.isShowingBack = (targetAngle == Float.pi)

            default:
                break
            }
        }

        func updateFlipState(showBack: Bool) {
            guard let cardNode = cardNode else { return }
            let targetAngle: Float = showBack ? Float.pi : 0

            guard abs(currentAngleY - targetAngle) > 0.01 else { return }
            currentAngleY = targetAngle

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            cardNode.eulerAngles = SCNVector3(0, targetAngle, 0)
            SCNTransaction.commit()
        }

        private func normalizeAngle(_ angle: Float) -> Float {
            var normalized = angle.truncatingRemainder(dividingBy: 2 * Float.pi)
            if normalized < 0 { normalized += 2 * Float.pi }
            return normalized
        }
    }
}
