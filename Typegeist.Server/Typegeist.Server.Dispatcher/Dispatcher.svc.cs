using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using System.Diagnostics;
using System.Data;
using System.Data.Objects;

using Typegeist.Server.Data;

namespace Typegeist.Server.Dispatcher
{
    public class Dispatcher : IDispatcher
    {
        public string GetData(int value)
        {
            return string.Format("You entered: {0}", value);
        }

        public void SubmitResult(TypegeistResult result)
        {
            Debug.WriteLine("SubmitResult! URL: {0}. {1} font families:", result.Url, result.FontFamilies.Count);

            foreach (FontFamilyData family in result.FontFamilies)
            {
                Debug.WriteLine("\t{0}: {1}", family.Family, family.Count);
            }
        }
    }
}
