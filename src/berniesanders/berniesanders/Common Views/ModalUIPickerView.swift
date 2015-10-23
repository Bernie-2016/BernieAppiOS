//
//  ModalUIPickerView.swift
//  berniesanders
//
//  Created by Nicolas Dedual on 10/22/15.
//  Copyright © 2015 Coders For Sanders. All rights reserved.
//

import UIKit

class ModalUIPickerView: UIView {

    var pickerView:UIPickerView = UIPickerView();
    var currentWindow:UIWindow? = nil
    var callToExecuteOnClose:((Int)->())!; // variable to store our data return function;
    
    init(pickerDataSource:UIPickerViewDataSource, pickerDelegate:UIPickerViewDelegate, backgroundColor:UIColor = UIColor.whiteColor(), accentColor:UIColor = UIColor.blackColor())
    {
        super.init(frame: CGRectZero);
        
        let delegate = UIApplication.sharedApplication()
        let myWindow:UIWindow? = delegate.keyWindow
        let myWindow2:NSArray = delegate.windows
        
        if let myWindow: UIWindow = UIApplication.sharedApplication().keyWindow
        {
            currentWindow = myWindow
        }
        else
        {
            currentWindow = myWindow2[0] as? UIWindow
        }
        
        pickerView.backgroundColor = backgroundColor
        self.frame = CGRectMake(0, UIScreen.mainScreen().bounds.size.height, UIScreen.mainScreen().bounds.size.width, 260.0)
        
        let kSCREEN_WIDTH  =    UIScreen.mainScreen().bounds.size.width
        
        pickerView.frame = CGRectMake(0.0, 44.0,kSCREEN_WIDTH, 216.0)
        pickerView.dataSource = pickerDataSource;
        pickerView.delegate = pickerDelegate;
        pickerView.showsSelectionIndicator = true;
        pickerView.backgroundColor = backgroundColor;
        
        let pickerDateToolbar = UIToolbar(frame: CGRectMake(0, 0, kSCREEN_WIDTH, 44))
        pickerDateToolbar.barStyle = UIBarStyle.Default
        pickerDateToolbar.barTintColor = accentColor
        pickerDateToolbar.translucent = true
        
        var barItems:[UIBarButtonItem] = [];
        
        let flexSpace: UIBarButtonItem
        flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: self, action: nil)
        flexSpace.width = 5;
        barItems.append(flexSpace)
        
        
        let labelCancel = UILabel()
        labelCancel.text = "Cancel"
        let titleCancel = UIBarButtonItem(title: labelCancel.text, style: UIBarButtonItemStyle.Plain, target: self, action: Selector("cancelPickerSelectionButtonClicked:"))
        barItems.append(titleCancel)
        
        let flexSpace2: UIBarButtonItem
        flexSpace2 = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: self, action: nil)
        barItems.append(flexSpace2)
        
        let doneBtn = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("doneClicked:"))
        barItems.append(doneBtn)
        
        let flexSpace3: UIBarButtonItem
        flexSpace3 = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: self, action: nil)
        flexSpace3.width = 5;
        barItems.append(flexSpace3)
        
        
        pickerDateToolbar.setItems(barItems, animated: true)
        
        self.addSubview(pickerDateToolbar)
        self.addSubview(pickerView)
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder);
        
    }
    
    func open(closeFunctionToExecute:(Int)->())
    {
        if (currentWindow != nil) {
            self.currentWindow!.addSubview(self)
        }
        
        self.callToExecuteOnClose = closeFunctionToExecute;
        
        UIView.animateWithDuration(0.2, animations: {
            
            self.frame = CGRectMake(0, UIScreen.mainScreen().bounds.size.height - 260.0, UIScreen.mainScreen().bounds.size.width, 260.0)
            
        })
    }
    
    func cancelPickerSelectionButtonClicked(sender: UIBarButtonItem) {
        
        UIView.animateWithDuration(0.2, animations: {
            
            self.frame = CGRectMake(0, UIScreen.mainScreen().bounds.size.height, UIScreen.mainScreen().bounds.size.width, 260.0)
            
            }, completion: { _ in
                for obj: AnyObject in self.subviews {
                    if let view = obj as? UIView
                    {
                        view.removeFromSuperview()
                    }
                }
        })
    }
    func doneClicked(sender: UIBarButtonItem) {
        
        
        let myRow = pickerView.selectedRowInComponent(0)
        
        self.callToExecuteOnClose(myRow);
        
        UIView.animateWithDuration(0.2, animations: {
            
            self.frame = CGRectMake(0, UIScreen.mainScreen().bounds.size.height, UIScreen.mainScreen().bounds.size.width, 260.0)
            
            }, completion: { _ in
                for obj: AnyObject in self.subviews {
                    if let view = obj as? UIView
                    {
                        view.removeFromSuperview()
                    }
                }
        })
    }
}
