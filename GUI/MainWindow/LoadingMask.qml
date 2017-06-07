import QtQuick 2.0

import Material 0.3

Rectangle {
	id: loadingMask

	z: 5
	color: Qt.rgba(0, 0, 0, 0.1)

	state: "non-visible"

	function show() {
		loadingMask.state = "visible"
	}

	function hide() {
		loadingMask.state = "non-visible"
	}

	states: [
		State {
			name: "non-visible"
			PropertyChanges {
				target: loadingMask
				enabled: false
				opacity: 0
			}
		},
		State {
			name: "visible"
			PropertyChanges {
				target: loadingMask
				enabled: true
				opacity: 1
			}
		}
	]

	transitions: [
		Transition {
			from: "visible"; to: "non-visible";
			SequentialAnimation {
				NumberAnimation {
					target: loadingMask;
					property: "opacity";
					easing.type: Easing.InOutQuad;
					duration: MaterialAnimation.pageTransitionDuration
				}
				PropertyAction {
					target: loadingMask;
					property: "visible";
					value: false
				}
			}
		},
		Transition {
			from: "non-visible"; to: "visible";
			SequentialAnimation {
				PropertyAction {
					target: loadingMask;
					property: "visible";
					value: true
				}
				NumberAnimation {
					target: loadingMask;
					property: "opacity";
					easing.type: Easing.InOutQuad;
					duration: MaterialAnimation.pageTransitionDuration
				}
			}
		}
	]

	ProgressCircle {
		anchors {
			horizontalCenter: parent.horizontalCenter
			verticalCenter: parent.verticalCenter
		}

		width: dp(27)
		height: dp(27)
		dashThickness: dp(4)

		color: Theme.accentColor
	}

	MouseArea {
		anchors.fill: parent

		acceptedButtons: Qt.AllButtons
		hoverEnabled: true

		onClicked: leftBar2.state = "narrow"
		onPressAndHold: {}
		onEntered: {}
		onExited: {}
	}
}
