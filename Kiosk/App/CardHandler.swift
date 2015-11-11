import UIKit
import ReactiveCocoa

class CardHandler: NSObject, CFTReaderDelegate {

    let cardSwipedSignal = RACSubject()
    var card: CFTCard?
    
    let APIKey: String
    let APIToken: String

    var reader: CFTReader!
    lazy var sessionManager = CFTSessionManager.sharedInstance()

    init(apiKey: String, accountToken: String){
        APIKey = apiKey
        APIToken = accountToken

        super.init()

        sessionManager.setApiToken(APIKey, accountToken: APIToken)
    }

    func startSearching() {
        sessionManager.setLogging(true)

        reader = CFTReader(reader: 1)
        reader.delegate = self;
        reader.swipeHasTimeout(false)
        cardSwipedSignal.sendNext("Started searching");
    }

    func end() {
        reader.cancelTransaction()
        reader = nil
    }

    func readerCardResponse(card: CFTCard?, withError error: NSError?) {
        if let card = card {
            self.card = card;
            cardSwipedSignal.sendNext("Got Card")

            card.tokenizeCardWithSuccess({ [weak self] () -> Void in
                self?.cardSwipedSignal.sendCompleted()
                logger.log("Card was tokenized")

            }, failure: { [weak self] (error) -> Void in
                self?.cardSwipedSignal.sendNext("Card Flight Error: \(error)");
                logger.log("Card was not tokenizable")
            })
            
        } else if let error = error {
            self.cardSwipedSignal.sendNext("response Error \(error)");
            logger.log("CardReader got a response it cannot handle")


            reader.beginSwipe();
        }
    }

    func transactionResult(charge: CFTCharge!, withError error: NSError!) {
        logger.log("Unexcepted call to transactionResult callback: \(charge)\n\(error)")
    }

    // handle other delegate call backs with the status messages

    func readerIsAttached() {
        cardSwipedSignal.sendNext("Reader is attatched");
    }

    func readerIsConnecting() {
        cardSwipedSignal.sendNext("Reader is connecting");
    }

    func readerIsDisconnected() {
        cardSwipedSignal.sendNext("Reader is disconnected");
        logger.log("Card Reader Disconnected")
    }

    func readerSwipeDidCancel() {
        cardSwipedSignal.sendNext("Reader did cancel");
        logger.log("Card Reader was Cancelled")
    }

    func readerGenericResponse(cardData: String!) {
        cardSwipedSignal.sendNext("Reader received non-card data: \(cardData) ");
        reader.beginSwipe();
    }

    func readerIsConnected(isConnected: Bool, withError error: NSError!) {
        if isConnected {
            cardSwipedSignal.sendNext("Reader is connected");
            reader.beginSwipe();

        } else {
            if (error != nil) {
                cardSwipedSignal.sendNext("Reader is disconnected: \(error.localizedDescription)");
            } else {
                cardSwipedSignal.sendNext("Reader is disconnected");
            }
        }
    }
}
