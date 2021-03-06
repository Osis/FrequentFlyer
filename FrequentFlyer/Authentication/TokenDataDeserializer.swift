import Foundation
import RxSwift

class TokenDataDeserializer {
    func deserialize(_ tokenData: Data) -> ReplaySubject<Token> {
        let $ = ReplaySubject<Token>.createUnbounded()

        var tokenDataJSONObject: Any?
        do {
            tokenDataJSONObject = try JSONSerialization.jsonObject(with: tokenData, options: .allowFragments)
        } catch { }

        guard let tokenDataDictionary = tokenDataJSONObject as? NSDictionary else {
            $.onError(DeserializationError(details: "Could not interpret data as JSON dictionary", type: .invalidInputFormat))
            return $
        }

        guard tokenDataDictionary.value(forKey: "value") != nil else {
            $.onError(DeserializationError(details: "Missing required 'value' key", type: .missingRequiredData))
            return $
        }

        guard let tokenValue = tokenDataDictionary["value"] as? String else {
            $.onError(DeserializationError(details: "Expected value for 'value' key to be a string", type: .typeMismatch))
            return $
        }

        $.onNext(Token(value: tokenValue))
        return $
    }
}
