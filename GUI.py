import sys
from PyQt5.QtWidgets import *
from PyQt5.QtGui import QFont


class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("FPGA Ray Tracer")
        self.setGeometry(150, 100, 1100, 650)

        self.initUI()

    def initUI(self):
        main_layout = QHBoxLayout()
        self.setStyleSheet("background-color: #444444;")

        # Left panel
        left_panel = QFrame()
        left_panel.setStyleSheet("background-color: lightgray; border-radius: 2px;")
        left_panel.setFrameShape(QFrame.StyledPanel)

        # Right panel
        right_panel = QFrame()
        right_panel.setStyleSheet("background-color: #555555; color: white; border-radius: 8px;")
        right_panel.setFrameShape(QFrame.StyledPanel)

        # Parameters layout
        parameters_layout = QVBoxLayout()
        parameters_layout.setContentsMargins(20, 20, 20, 20)

        # Title for right panel
        title_label = QLabel("Parameters")
        title_label.setFont(QFont("Helvetica", 22))
        title_label.setStyleSheet("color: white;")

        parameters_layout.addWidget(title_label)

        parameters_layout.addItem(QSpacerItem(20, 20, QSizePolicy.Minimum, QSizePolicy.Fixed))

        helvetica_font = QFont("Helvetica", 14)

        labels = [
            "Image Height:",
            "Image Width:",
            "Camera Position (x, y, z):",
            "Camera Direction (x, y, z):",
            "Camera Distance:"
        ]

        # Input boxes
        self.input_boxes = []
        for label_text in labels:
            label = QLabel(label_text)
            label.setFont(helvetica_font)
            input_box = QLineEdit()
            input_box.setFixedSize(150, 30)
            input_box.setFont(helvetica_font)
            input_box.setStyleSheet("background-color: #333333; color: white; border: 1px solid gray; border-radius: 5px;")
            self.input_boxes.append(input_box)

            hbox = QHBoxLayout()
            hbox.addWidget(label)
            hbox.addWidget(input_box)
            parameters_layout.addLayout(hbox)

        # Error label
        self.error_label = QLabel()
        self.error_label.setStyleSheet("color: rgba(255, 0, 0, 150);")
        self.error_label.setFont(helvetica_font)
        parameters_layout.addWidget(self.error_label)

        parameters_layout.addItem(QSpacerItem(0, 0, QSizePolicy.Minimum, QSizePolicy.Expanding))

        submit_button = QPushButton("Submit")
        submit_button.clicked.connect(self.submit)
        submit_button.setFont(helvetica_font)
        submit_button.setStyleSheet("QPushButton {background-color: #3498db; color: white; border-radius: 5px; min-height: 40px;}"
                                    "QPushButton:pressed {background-color: #2980b9;}")
        parameters_layout.addWidget(submit_button)

        right_panel.setLayout(parameters_layout)

        # Splitter
        splitter = QSplitter()
        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setCollapsible(0, False)  # Make left panel non-collapsible
        initial_width = int(self.width() * 0.7)
        splitter.setSizes([initial_width, self.width() - initial_width])

        main_layout.addWidget(splitter)

        self.setLayout(main_layout)

    def submit(self):
        empty_fields = [field for field in self.input_boxes if not field.text()]
        if empty_fields:
            self.error_label.setText("Please fill in all the fields.")
        else:
            if self.validateInput():
                self.error_label.clear()
                values = self.getValues()
                # Call some external function here with values as a parameter probably
                print("INPUT DATA: ", values)
            else:
                self.error_label.setText("Please enter valid data.")

    def validateInput(self):
        for i, input_box in enumerate(self.input_boxes):
            if i == 0 or i == 1 or i == 4:
                try:
                    int(input_box.text())
                except ValueError:
                    return False
            elif i == 2 or i == 3:
                data = input_box.text().replace(" ", "").split(",")
                if len(data) != 3:
                    return False
                for d in data:
                    try:
                        int(d)
                    except ValueError:
                        return False
            else:
                return False
        return True

    def getValues(self):
        values = []
        for i, input_box in enumerate(self.input_boxes):
            if i == 0 or i == 1 or i == 4:
                values.append(int(input_box.text()))
            elif i == 2 or i == 3:
                data = input_box.text().replace(" ", "").split(",")
                values.extend(int(d) for d in data)
        return values


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec_())
