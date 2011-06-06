using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;

namespace Typegeist.Server.Dispatcher
{
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the interface name "IService1" in both code and config file together.
    [ServiceContract]
    public interface IDispatcher
    {
        [OperationContract]
        [WebInvoke(
            Method = "POST",
            BodyStyle = WebMessageBodyStyle.Bare
        )]
        void SubmitResult(TypegeistResult result);

        [OperationContract]
        [WebGet]
        string GetData(int value);
    }


    [DataContract]
    public class TypegeistResult
    {
        [DataMember]
        public string Url { get; set; }

        [DataMember]
        public Dictionary<string, int> FontFamilyCount { get; set; }
    }
}
