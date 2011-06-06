using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using System.Web.Script.Services;

namespace Typegeist.Server.Dispatcher
{
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the interface name "IService1" in both code and config file together.
    [ServiceContract]
    public interface IDispatcher
    {
        [OperationContract]
        [WebInvoke(
            Method = "POST",
            RequestFormat = WebMessageFormat.Json,
            ResponseFormat = WebMessageFormat.Json,
            BodyStyle = WebMessageBodyStyle.Bare
        )]
        void SubmitResult(TypegeistResult result);
    }

    [DataContract]
    public class FontFamilyData
    {
        [DataMember]
        public string Family { get; set; }

        [DataMember]
        public int Count { get; set; }
    }

    [DataContract]
    public class TypegeistResult
    {
        [DataMember]
        public string Url { get; set; }

        [DataMember]
        public List<FontFamilyData> FontFamilies { get; set; }
    }
}
