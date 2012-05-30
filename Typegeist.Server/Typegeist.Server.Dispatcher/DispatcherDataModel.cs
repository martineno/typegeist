using System;
using System.Collections.Generic;
using System.Data.Objects;
using System.Linq;
using System.Web;
using Typegeist.Server.Data;

namespace Typegeist.Server.Dispatcher
{
    internal static class DispatcherDataModel
    {
        static DispatcherDataModel()
        {
            _data = new TypegeistDataSetContainer();
        }

        public void AddResult(TypegeistResult result)
        {

        }

        private static TypegeistDataSetContainer _data;
    }
}