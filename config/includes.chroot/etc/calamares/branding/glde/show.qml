/* GLDE Calamares slideshow */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 12000
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            id: background1
            source: "slide1.png"
            width: 467; height: 280
            fillMode: Image.PreserveAspectCrop
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: background1.horizontalCenter
            anchors.top: background1.bottom
            text: qsTr("Добро пожаловать в GreenLinux Debian Edition.<br/>" +
                  "Установка полностью автоматизирована и займёт несколько минут.")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
            color: "#1d5c2c"
        }
    }

    Slide {
        Image {
            id: background2
            source: "slide2.jpg"
            width: 467; height: 280
            fillMode: Image.PreserveAspectCrop
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: background2.horizontalCenter
            anchors.top: background2.bottom
            text: qsTr("Основным браузером в GLDE является Яндекс Браузер,<br/>" +
                  "а сертификаты Минцифры уже интегрированы в систему.")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
            color: "#1d5c2c"
        }
    }

    Slide {
        Image {
            id: background3
            source: "slide3.jpg"
            width: 467; height: 280
            fillMode: Image.PreserveAspectCrop
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: background3.horizontalCenter
            anchors.top: background3.bottom
            text: qsTr("Спасибо, что выбрали Green Linux.<br/>" +
                  "Зелёного вам неба!")
            wrapMode: Text.WordWrap
            width: 600
            horizontalAlignment: Text.Center
            color: "#1d5c2c"
        }
    }
}
