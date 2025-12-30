Sub GeneratePresentation()
    Dim pptApp As Object
    Dim pptPres As Object
    Dim currentSlide As Object
    Dim slideIndex As Integer
    Dim shp As Object
    
    ' Define Theme Colors
    Const RGB_BLUE As Long = 10510349 ' RGB(13, 71, 161)
    Const RGB_BLACK As Long = 2171169 ' RGB(33, 33, 33)
    Const RGB_AMBER As Long = 3329330 ' RGB(255, 111, 0)
    Const RGB_WHITE As Long = 16777215
    Const RGB_LIGHT_GRAY As Long = 14737632
    
    ' Create PowerPoint Application
    On Error Resume Next
    Set pptApp = CreateObject("PowerPoint.Application")
    If pptApp Is Nothing Then
        MsgBox "PowerPoint is not installed."
        Exit Sub
    End If
    On Error GoTo 0
    
    pptApp.Visible = True
    Set pptPres = pptApp.Presentations.Add
    
    ' --- Helper Logic Inline ---
    
    ' ==========================================
    ' Slide 1: Title Slide
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 1) ' ppLayoutTitle
    Call ApplyDarkTheme(currentSlide)
    
    ' Title Styling
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "College Bus Tracking System"
        .Font.Color.RGB = RGB_WHITE
        .Font.Bold = msoTrue
        .Font.Size = 44
    End With
    
    ' Subtitle Styling
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "A Real-Time Location Tracking Solution" & vbCrLf & _
                "Student: [Your Name] | Roll No: [Roll]" & vbCrLf & _
                "Dept: ECE / CSE | Year: 2025"
        .Font.Color.RGB = RGB_LIGHT_GRAY
        .Font.Size = 20
    End With
    
    ' Icon Element: Bus Icon (Rounded Rectangle proxy)
    Set shp = currentSlide.Shapes.AddShape(msoShapeRoundedRectangle, 400, 200, 150, 60)
    shp.Fill.ForeColor.RGB = RGB_AMBER
    shp.Line.Visible = msoFalse
    shp.TextFrame.TextRange.Text = "BUS TRACKER"
    shp.TextFrame.TextRange.Font.Bold = msoTrue
    
    ' ==========================================
    ' Slide 2: Problem Statement
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 2) ' ppLayoutText
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "The Need for Real-Time Tracking"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "Current Scenario:" & vbCrLf & _
            "- Lack of visibility: Students wait indefinitely." & vbCrLf & _
            "- Communication gaps: Parents worry about delays." & vbCrLf & vbCrLf & _
            "Motivation:" & vbCrLf & _
            "- Ensure student safety through monitoring." & vbCrLf & _
            "- Optimize waiting times and reduce anxiety."
        .Font.Color.RGB = RGB_WHITE
    End With
    
    ' Icon Element: Warning Sign shape
    Set shp = currentSlide.Shapes.AddShape(msoShapeIsoscelesTriangle, 800, 50, 80, 70)
    shp.Fill.ForeColor.RGB = RGB(255, 0, 0)
    shp.Line.Visible = msoFalse
    shp.TextFrame.TextRange.Text = "!"
    
    ' ==========================================
    ' Slide 3: Objectives
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 2)
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "Key Objectives"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "1. Real-Time Tracking (< 5s latency)." & vbCrLf & _
                "2. Role-Based Access (Secure Portals)." & vbCrLf & _
                "3. Automated Alerts (Push Notifications)." & vbCrLf & _
                "4. Route Management (Dynamic Assignment)."
        .Font.Color.RGB = RGB_WHITE
    End With
    
    ' Icon Element: Target
    Set shp = currentSlide.Shapes.AddShape(msoShapeDonut, 800, 100, 80, 80)
    shp.Fill.ForeColor.RGB = RGB_BLUE
    
    ' ==========================================
    ' Slide 4: Tech Stack
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 2)
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "Tools & Technologies"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "- Mobile: Flutter (Dart)" & vbCrLf & _
                "- Backend: Node.js & Express" & vbCrLf & _
                "- Real-Time: Socket.IO" & vbCrLf & _
                "- Database: MongoDB" & vbCrLf & _
                "- API: Google Maps"
        .Font.Color.RGB = RGB_WHITE
    End With
    
    ' Icon Element: Stack Layers
    Set shp = currentSlide.Shapes.AddShape(msoShapeCan, 750, 150, 60, 80)
    shp.Fill.ForeColor.RGB = RGB_LIGHT_GRAY
    
    ' ==========================================
    ' Slide 5: Architecture
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 2)
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "System Architecture"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "- Flutter App <-> Node.js API" & vbCrLf & _
                "- REST API for Auth & Data" & vbCrLf & _
                "- Socket.IO for Live Events" & vbCrLf & _
                "- MongoDB for Persistence"
        .Font.Color.RGB = RGB_WHITE
    End With
    
    ' Schematic Placeholder
    Set shp = currentSlide.Shapes.AddShape(msoShapeFlowchartProcess, 400, 300, 150, 80)
    shp.TextFrame.TextRange.Text = "API Server"
    shp.Fill.ForeColor.RGB = RGB_BLUE
    
    ' ==========================================
    ' Slide 6: Real-Time Flow
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 2)
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "Real-Time Tracking Logic"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "1. Driver Emits Location (Socket)" & vbCrLf & _
                "2. Server Validates Token" & vbCrLf & _
                "3. Server Broadcasts to Room" & vbCrLf & _
                "4. Student Receives Update"
        .Font.Color.RGB = RGB_WHITE
    End With
    
    ' Flow Icon - Arrow
    Set shp = currentSlide.Shapes.AddShape(msoShapeRightArrow, 500, 200, 100, 50)
    shp.Fill.ForeColor.RGB = RGB_AMBER
    
    ' ==========================================
    ' Slide 7: Challenges
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 2)
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "Challenges & Solutions"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "Challenge: Battery Drain" & vbCrLf & _
                "Solution: Adaptive Sampling Rate" & vbCrLf & vbCrLf & _
                "Challenge: Latency" & vbCrLf & _
                "Solution: WebSockets & Binary Data"
        .Font.Color.RGB = RGB_WHITE
    End With
    
    ' Icon: Lightning Bolt
    Set shp = currentSlide.Shapes.AddShape(msoShapeLightningBolt, 800, 50, 50, 80)
    shp.Fill.ForeColor.RGB = RGB_AMBER
    
    ' ==========================================
    ' Slide 8: Conclusion
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 1)
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "Conclusion"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "A Robust, Scalable Tracking System" & vbCrLf & _
                "Enhancing Campus Safety"
        .Font.Color.RGB = RGB_WHITE
        .Font.Size = 24
    End With
    
    ' ==========================================
    ' Slide 9: Q&A
    ' ==========================================
    slideIndex = slideIndex + 1
    Set currentSlide = pptPres.Slides.Add(slideIndex, 1)
    Call ApplyDarkTheme(currentSlide)
    
    With currentSlide.Shapes(1).TextFrame.TextRange
        .Text = "Questions?"
        .Font.Color.RGB = RGB_WHITE
    End With
    
    With currentSlide.Shapes(2).TextFrame.TextRange
        .Text = "Thank You"
        .Font.Color.RGB = RGB_AMBER
    End With
    
    MsgBox "Presentation Generated with Themes!", vbInformation
End Sub

Sub ApplyDarkTheme(slide As Object)
    ' Apply Blue-Black Gradient Background
    With slide.Background.Fill
        .Visible = msoTrue
        .ForeColor.RGB = RGB(13, 71, 161) ' Deep Blue
        .BackColor.RGB = RGB(0, 0, 0)     ' Black
        .TwoColorGradient msoGradientHorizontal, 1
    End With
End Sub
