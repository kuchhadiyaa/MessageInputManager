//
//  ViewController.swift
//  MessageInputManager
//
//  Created by kuchhadiyaa on 08/22/2018.
//  Copyright (c) 2018 kuchhadiyaa. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		(view as! ConversationDetailView).becomeFirstResponder()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
}

